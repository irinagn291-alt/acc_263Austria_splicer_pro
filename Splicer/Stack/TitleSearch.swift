import Foundation

/// Discover transport. One client owns search and the single-title lookup.
protocol TitleTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct SessionTransport: TitleTransport {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

enum TitleSearchError: Error, Equatable, Sendable {
    case malformedURL
    case notFound
    case transport
    case decoding
    case cancelled
}

struct SearchPageDTO: Decodable, Sendable {
    var products: [SearchHitDTO]?
}

struct SearchHitDTO: Decodable, Sendable {
    var code: String?
    var product_name: String?
}

struct ProductEnvelopeDTO: Decodable, Sendable {
    var status: Int?
    var product: SearchHitDTO?
}

/// cgi/search.pl plus product lookup. DTOs stay here. Stubs are the domain mapping.
struct TitleSearch: Sendable {
    static let userAgent = "Splicer/1.0 (iOS; +https://splicer-lane.pro)"
    static let pageSize = 20

    private let transport: TitleTransport
    private let decoder: JSONDecoder

    init(transport: TitleTransport) {
        self.transport = transport
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    func search(terms: String) async throws -> [Stub] {
        let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        guard var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl") else {
            throw TitleSearchError.malformedURL
        }
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: trimmed),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: String(Self.pageSize)),
            URLQueryItem(name: "fields", value: "code,product_name")
        ]
        guard let url = components.url else { throw TitleSearchError.malformedURL }
        let data = try await load(url: url)
        let page: SearchPageDTO
        do {
            page = try decoder.decode(SearchPageDTO.self, from: data)
        } catch {
            throw TitleSearchError.decoding
        }
        return (page.products ?? []).compactMap(Self.stub(from:))
    }

    func resolve(code: String) async throws -> Stub {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(encoded).json")
        else {
            throw TitleSearchError.malformedURL
        }
        let data = try await load(url: url)
        let envelope: ProductEnvelopeDTO
        do {
            envelope = try decoder.decode(ProductEnvelopeDTO.self, from: data)
        } catch {
            throw TitleSearchError.decoding
        }
        if envelope.status == 0 {
            throw TitleSearchError.notFound
        }
        guard let stub = envelope.product.flatMap(Self.stub(from:)) else {
            throw TitleSearchError.notFound
        }
        return stub
    }

    private func load(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        do {
            return try await send(request, allowRetry: true)
        } catch is CancellationError {
            throw TitleSearchError.cancelled
        }
    }

    private func send(_ request: URLRequest, allowRetry: Bool) async throws -> Data {
        do {
            let (data, response) = try await transport.data(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else {
                throw TitleSearchError.transport
            }
            if http.statusCode == 404 {
                throw TitleSearchError.notFound
            }
            guard (200...299).contains(http.statusCode) else {
                throw TitleSearchError.transport
            }
            return data
        } catch let error as TitleSearchError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch {
            guard allowRetry, Self.isTransient(error) else {
                throw TitleSearchError.transport
            }
            return try await send(request, allowRetry: false)
        }
    }

    private static func isTransient(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost, .dnsLookupFailed:
            return true
        default:
            return false
        }
    }

    private static func stub(from hit: SearchHitDTO) -> Stub? {
        guard let name = hit.product_name?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }
        return Stub(title: name, catalogueCode: hit.code)
    }
}

/// Cancels the previous query so a late payload cannot replace a newer one.
@MainActor
final class DiscoverQuery {
    private let search: TitleSearch
    private let shelf: [Stub]
    private let debounceNanoseconds: UInt64
    private var task: Task<Void, Never>?
    private var ticket = 0
    private(set) var results: [Stub] = []
    private(set) var failure: TitleSearchError?

    init(search: TitleSearch, shelf: [Stub], debounceNanoseconds: UInt64 = 300_000_000) {
        self.search = search
        self.shelf = shelf
        self.debounceNanoseconds = debounceNanoseconds
    }

    func update(terms: String) {
        task?.cancel()
        ticket += 1
        let mine = ticket
        let wait = debounceNanoseconds
        task = Task {
            if wait > 0 {
                do {
                    try await Task.sleep(nanoseconds: wait)
                } catch {
                    return
                }
            }
            guard !Task.isCancelled, mine == self.ticket else { return }
            let trimmed = terms.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                self.results = self.shelf
                self.failure = nil
                return
            }
            do {
                let found = try await self.search.search(terms: trimmed)
                guard !Task.isCancelled, mine == self.ticket else { return }
                self.results = found.isEmpty ? self.shelf : found
                self.failure = nil
            } catch let error as TitleSearchError {
                guard !Task.isCancelled, mine == self.ticket else { return }
                self.results = self.shelf
                self.failure = error
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled, mine == self.ticket else { return }
                self.results = self.shelf
                self.failure = .transport
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}

enum LocalShelf {
    static let titles: [Stub] = [
        Stub(id: UUID(uuidString: "A1000001-0000-4000-8000-000000000001") ?? UUID(), title: "Night Ferry"),
        Stub(id: UUID(uuidString: "A1000001-0000-4000-8000-000000000002") ?? UUID(), title: "Glass Orchard"),
        Stub(id: UUID(uuidString: "A1000001-0000-4000-8000-000000000003") ?? UUID(), title: "Low Tide Ledger"),
        Stub(id: UUID(uuidString: "A1000001-0000-4000-8000-000000000004") ?? UUID(), title: "Copper Hour")
    ]
}

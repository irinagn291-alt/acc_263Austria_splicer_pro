import XCTest
@testable import Splicer

final class SplicerTests: XCTestCase {
    func test_burnShrinksTheBoardInsteadOfKeepingASeenShelf() {
        var fold = BoardFold()
        let first = Stub(title: "Night Ferry")
        let second = Stub(title: "Glass Orchard")
        fold.stash(first)
        fold.stash(second)
        XCTAssertEqual(fold.phase, .piled)
        XCTAssertEqual(fold.draw(), .seated(first))
        XCTAssertEqual(fold.phase, .gated)
        guard case .marked(let burn) = fold.burn(on: Date(timeIntervalSince1970: 1_700_000_000)) else {
            XCTFail("Burn should mark the gate")
            return
        }
        XCTAssertEqual(burn.title, "Night Ferry")
        XCTAssertNil(fold.gate)
        XCTAssertEqual(fold.stack.map(\.title), ["Glass Orchard"])
        XCTAssertEqual(fold.phase, .piled)
        XCTAssertEqual(fold.burnMarks.map(\.title), ["Night Ferry"])
        XCTAssertFalse(fold.stack.contains(where: { $0.id == first.id }))
    }

    func test_drawAndBurnRefusals() {
        var empty = BoardFold()
        XCTAssertEqual(empty.phase, .dark)
        XCTAssertEqual(empty.draw(), .bare)
        XCTAssertEqual(empty.phase, .dark)
        if case .refusedWhileDark = empty.burn(on: Date()) {
        } else {
            XCTFail("Burn on a dark board is refused")
        }

        var piled = BoardFold(stack: [Stub(title: "Copper Hour")])
        if case .refusedWhilePiled = piled.burn(on: Date()) {
        } else {
            XCTFail("Burn on a pile is refused")
        }
        XCTAssertEqual(piled.stack.count, 1)

        _ = piled.draw()
        XCTAssertEqual(piled.draw(), .refusedWhileGated)
        XCTAssertNotNil(piled.gate)
        XCTAssertTrue(piled.stack.isEmpty)
    }

    func test_gradeFoldsOnlyOntoBurnMarks() {
        var fold = BoardFold()
        let stub = Stub(title: "Low Tide Ledger")
        fold.stash(stub)
        _ = fold.draw()
        guard case .marked(let burn) = fold.burn(on: Date()) else {
            XCTFail("Expected a burn")
            return
        }
        XCTAssertFalse(fold.grade(burnID: burn.id, stars: 0))
        XCTAssertFalse(fold.grade(burnID: burn.id, stars: 6))
        XCTAssertFalse(fold.grade(burnID: UUID(), stars: 4))
        XCTAssertTrue(fold.grade(burnID: burn.id, stars: 4))
        XCTAssertEqual(fold.burnMarks.first?.grade, SpliceGrade(stars: 4))
        XCTAssertNil(fold.gate)
    }

    func test_slipKeepsTheGateAndAshStaysBurnOrder() {
        var fold = BoardFold()
        fold.stash(Stub(title: "One"))
        fold.stash(Stub(title: "Two"))
        _ = fold.draw()
        XCTAssertNotNil(fold.slip(on: Date()))
        XCTAssertEqual(fold.phase, .gated)
        XCTAssertEqual(fold.burnMarks.count, 0)
        _ = fold.burn(on: Date())
        _ = fold.draw()
        _ = fold.burn(on: Date())
        XCTAssertEqual(fold.burnMarks.map(\.title), ["One", "Two"])
        XCTAssertEqual(fold.phase, .empty)
    }

    func test_laneFoldPhases() {
        var fold = BoardFold()
        XCTAssertEqual(fold.phase, .dark)
        fold.stash(Stub(title: "A"))
        XCTAssertEqual(fold.phase, .piled)
        _ = fold.draw()
        XCTAssertEqual(fold.phase, .gated)
        _ = fold.burn(on: Date())
        XCTAssertEqual(fold.phase, .empty)
        fold.stash(Stub(title: "B"))
        XCTAssertEqual(fold.phase, .piled)
    }

    func test_dayStampUsesStartOfDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        let evening = Date(timeIntervalSince1970: 1_720_000_000)
        let stamp = BurnMark.dayStamp(for: evening, calendar: calendar)
        let start = calendar.startOfDay(for: evening)
        let parts = calendar.dateComponents([.year, .month, .day], from: start)
        let expected = (parts.year ?? 0) * 10_000 + (parts.month ?? 0) * 100 + (parts.day ?? 0)
        XCTAssertEqual(stamp, expected)
        XCTAssertGreaterThan(stamp, 20_000_000)
    }

    func test_rateDeskFitAndPositions() {
        let fit = RateDesk.fit(samples: [(0, 0), (1, 2), (2, 4)])
        XCTAssertNotNil(fit, "OLS slope is seconds per day")
        XCTAssertEqual(fit?.secondsPerDay ?? -1, 2, accuracy: 0.0001)
        XCTAssertEqual(fit?.rSquared ?? -1, 1, accuracy: 0.0001)
        XCTAssertEqual(fit?.withinCOSC, true)
        let fast = RateDesk.fit(samples: [(0, 0), (1, 5)])
        XCTAssertEqual(fast?.withinCOSC, false)
        let spread = RateDesk.Positions(dialUp: 1, dialDown: 2, crownUp: 3, crownLeft: -1, crownDown: 0)
        XCTAssertEqual(spread.spread, 4, accuracy: 0.0001)
        XCTAssertNil(RateDesk.fit(samples: [(1, 1)]))
    }

    func test_chartRoundTripAndReset() async {
        let suite = "splicer.tests.\(UUID().uuidString)"
        guard let store = LaneChartStore.makeSuite(suite, debounceNanoseconds: 0) else {
            XCTFail("Suite defaults")
            return
        }
        await store.stash(Stub(title: "Night Ferry"))
        let drawn = await store.draw()
        guard case .seated = drawn else {
            XCTFail("Draw")
            return
        }
        _ = await store.burn(on: Date(timeIntervalSince1970: 1_700_000_000))
        await store.flush()
        guard let reloaded = LaneChartStore.openSuite(suite, debounceNanoseconds: 0) else {
            XCTFail("Reload suite")
            return
        }
        let chart = await reloaded.snapshot()
        XCTAssertEqual(chart.burnMarks.map(\.title), ["Night Ferry"])
        XCTAssertNil(chart.gate)
        XCTAssertTrue(chart.stack.isEmpty)
        XCTAssertEqual(chart.schemaVersion, 1)
        await store.resetAllData()
        let present = await store.recordIsPresent()
        XCTAssertFalse(present)
        let cleared = await store.snapshot()
        XCTAssertTrue(cleared.burnMarks.isEmpty)
    }

    func test_corruptChartFallsBackThenEmpties() async {
        let suite = "splicer.corrupt.\(UUID().uuidString)"
        let good = LaneChart(stack: [Stub(title: "Kept")])
        let encoder = JSONEncoder()
        guard let backup = try? encoder.encode(good) else {
            XCTFail("Encode")
            return
        }
        guard let restored = LaneChartStore.makeSuite(
            suite,
            record: Data("not-json".utf8),
            backup: backup
        ) else {
            XCTFail("Suite defaults")
            return
        }
        let fromBackup = await restored.snapshot()
        let restoredLoad = await restored.load
        XCTAssertEqual(restoredLoad, .restoredFromBackup)
        XCTAssertEqual(fromBackup.stack.map(\.title), ["Kept"])

        guard let emptied = LaneChartStore.makeSuite(
            suite + ".empty",
            record: Data("still-bad".utf8),
            backup: Data("{".utf8)
        ) else {
            XCTFail("Empty suite")
            return
        }
        let emptiedLoad = await emptied.load
        XCTAssertEqual(emptiedLoad, .emptyAfterCorruption)
        let empty = await emptied.snapshot()
        XCTAssertTrue(empty.stack.isEmpty)
        XCTAssertEqual(empty.schemaVersion, 1)
    }

    func test_unknownSchemaIsRejected() throws {
        let payload = #"{"schemaVersion":9,"stack":[]}"#.data(using: .utf8) ?? Data()
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        XCTAssertThrowsError(try decoder.decode(LaneChart.self, from: payload))
    }

    func test_reviewScreenParser() {
        XCTAssertEqual(ReviewLaunch.surface(from: ["-ReviewScreen", "today"]), .today)
        XCTAssertEqual(ReviewLaunch.surface(from: ["-ReviewScreen", "log"]), .log)
        XCTAssertEqual(ReviewLaunch.surface(from: ["-ReviewScreen", "goals"]), .goals)
        XCTAssertEqual(ReviewLaunch.surface(from: ["-ReviewScreen", "discover"]), .discover)
        XCTAssertEqual(ReviewLaunch.surface(from: ["App", "-ReviewScreen", "settings"]), .settings)
        XCTAssertNil(ReviewLaunch.surface(from: ["-ReviewScreen"]))
        XCTAssertNil(ReviewLaunch.surface(from: ["-ReviewScreen", "queue"]))
    }

    func test_searchDecodesTitlesAndRetriesOnce() async throws {
        let payload = #"{"products":[{"code":"123","product_name":"Night Ferry"},{"code":"9","product_name":"  "}]}"#
        let transport = ScriptedTransport(steps: [
            .failure(URLError(.networkConnectionLost)),
            .success(Data(payload.utf8), 200)
        ])
        let search = TitleSearch(transport: transport)
        let stubs = try await search.search(terms: "ferry")
        XCTAssertEqual(stubs.map(\.title), ["Night Ferry"])
        let calls = await transport.calls
        XCTAssertEqual(calls, 2)
        let request = await transport.requests.first
        XCTAssertEqual(request?.value(forHTTPHeaderField: "User-Agent"), TitleSearch.userAgent)
        XCTAssertTrue(request?.url?.absoluteString.contains("/cgi/search.pl") ?? false)
        XCTAssertEqual(request?.timeoutInterval, 15)
    }

    func test_searchDoesNotRetryNotFound() async {
        let transport = ScriptedTransport(steps: [
            .success(Data(#"{"status":0,"product":null}"#.utf8), 200)
        ])
        let search = TitleSearch(transport: transport)
        do {
            _ = try await search.resolve(code: "000")
            XCTFail("Expected not found")
        } catch TitleSearchError.notFound {
        } catch {
            XCTFail("Unexpected \(error)")
        }
        let calls = await transport.calls
        XCTAssertEqual(calls, 1)
    }

    func test_malformedSearchIsAnError() async {
        let transport = ScriptedTransport(steps: [
            .success(Data("[]".utf8), 200)
        ])
        let search = TitleSearch(transport: transport)
        do {
            _ = try await search.search(terms: "x")
            XCTFail("Expected decoding")
        } catch TitleSearchError.decoding {
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func test_http404IsNotRetried() async {
        let transport = ScriptedTransport(steps: [
            .success(Data("{}".utf8), 404),
            .success(Data(#"{"products":[]}"#.utf8), 200)
        ])
        let search = TitleSearch(transport: transport)
        do {
            _ = try await search.search(terms: "missing")
            XCTFail("Expected not found")
        } catch TitleSearchError.notFound {
        } catch {
            XCTFail("Unexpected \(error)")
        }
        let calls = await transport.calls
        XCTAssertEqual(calls, 1)
    }

    @MainActor
    func test_queryChangeDropsStaleResults() async {
        let transport = ScriptedTransport(steps: [
            .success(Data(#"{"products":[{"product_name":"Stale"}]}"#.utf8), 200),
            .success(Data(#"{"products":[{"product_name":"Fresh"}]}"#.utf8), 200)
        ], holdFirst: true)
        let query = DiscoverQuery(
            search: TitleSearch(transport: transport),
            shelf: LocalShelf.titles,
            debounceNanoseconds: 0
        )
        query.update(terms: "stale")
        let started = Date().addingTimeInterval(1)
        while await transport.calls < 1, Date() < started {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        query.update(terms: "fresh")
        let both = Date().addingTimeInterval(1)
        while await transport.calls < 2, Date() < both {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        let deadline = Date().addingTimeInterval(1)
        while query.results.map(\.title) != ["Fresh"], Date() < deadline {
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
        await transport.releaseFirst()
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(query.results.map(\.title), ["Fresh"])
        let calls = await transport.calls
        XCTAssertEqual(calls, 2)
    }
}

private actor ScriptedTransport: TitleTransport {
    enum Step: Sendable {
        case success(Data, Int)
        case failure(URLError)
    }

    private var steps: [Step]
    private(set) var requests: [URLRequest] = []
    private let holdFirst: Bool
    private let firstLatch = ResponseLatch()

    init(steps: [Step], holdFirst: Bool = false) {
        self.steps = steps
        self.holdFirst = holdFirst
    }

    var calls: Int { requests.count }

    func releaseFirst() {
        firstLatch.release()
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        guard !steps.isEmpty else {
            throw URLError(.badServerResponse)
        }
        let step = steps.removeFirst()
        if holdFirst, requests.count == 1 {
            await firstLatch.park()
        }
        switch step {
        case .success(let data, let status):
            guard let response = HTTPURLResponse(
                url: request.url ?? URL(fileURLWithPath: "/"),
                statusCode: status,
                httpVersion: nil,
                headerFields: nil
            ) else {
                throw URLError(.badServerResponse)
            }
            return (data, response)
        case .failure(let error):
            throw error
        }
    }
}

/// Holds the first scripted response until the test releases it.
private final class ResponseLatch: @unchecked Sendable {
    private let lock = NSLock()
    private var released = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func park() async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            lock.lock()
            if released {
                lock.unlock()
                continuation.resume()
                return
            }
            waiters.append(continuation)
            lock.unlock()
        }
    }

    func release() {
        lock.lock()
        released = true
        let pending = waiters
        waiters.removeAll()
        lock.unlock()
        for waiter in pending {
            waiter.resume()
        }
    }
}

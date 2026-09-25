import SwiftUI

/// Search sheet. Empty query and failed search both show the local shelf. No play links.
@MainActor
final class DiscoverDesk: ObservableObject {
    @Published var terms = ""
    @Published private(set) var results: [Stub] = LocalShelf.titles
    @Published private(set) var failure: TitleSearchError?
    @Published private(set) var loading = false

    private let search: TitleSearch
    private var task: Task<Void, Never>?

    init(search: TitleSearch = TitleSearch(transport: SessionTransport())) {
        self.search = search
    }

    func edit(_ text: String) {
        terms = text
        task?.cancel()
        loading = false
        let snapshot = text
        task = Task {
            let trimmed = snapshot.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                results = LocalShelf.titles
                failure = nil
                loading = false
                return
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            loading = true
            do {
                let found = try await search.search(terms: trimmed)
                guard !Task.isCancelled else { return }
                if found.isEmpty {
                    results = LocalShelf.titles
                    failure = .notFound
                } else {
                    results = found
                    failure = nil
                }
            } catch let error as TitleSearchError {
                guard !Task.isCancelled else { return }
                results = LocalShelf.titles
                failure = error
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                results = LocalShelf.titles
                failure = .transport
            }
            loading = false
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        loading = false
    }
}

struct DiscoverSheet: View {
    @ObservedObject var desk: DiscoverDesk
    var stash: (Stub) -> Void
    @Environment(\.dismiss) private var dismiss
    @FocusState private var searchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
                TextField("Search a title", text: Binding(
                    get: { desk.terms },
                    set: { desk.edit($0) }
                ))
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.ink)
                .padding(SpliceTokens.space(2))
                .frame(minHeight: SpliceTokens.space(6))
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous)
                        .strokeBorder(searchFocused ? DesignTokens.ink : DesignTokens.muted, lineWidth: SpliceTokens.hairline)
                }
                .focused($searchFocused)
                .submitLabel(.search)
                .accessibilityLabel("Search a title")

                HeldProgress(active: desk.loading)

                if let failure = desk.failure {
                    Text(message(for: failure))
                        .spliceFace(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Search again") {
                        desk.edit(desk.terms)
                    }
                    .buttonStyle(BurnChromeStyle(loading: false, enabled: !desk.loading))
                    .disabled(desk.loading)
                }

                if desk.results.isEmpty {
                    empty
                } else {
                    List(desk.results) { stub in
                        Button {
                            searchFocused = false
                            stash(stub)
                        } label: {
                            VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                                Text(stub.title)
                                    .spliceFace(.body)
                                    .foregroundStyle(DesignTokens.ink)
                                    .lineLimit(2)
                                Text("Stash on the stack")
                                    .spliceFace(.micro)
                                    .foregroundStyle(DesignTokens.muted)
                            }
                            .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6), alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(InkPressStyle())
                        .listRowBackground(DesignTokens.surface)
                    }
                    .listStyle(.plain)
                    .scrollDismissesKeyboard(.immediately)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let facts = URL(string: "https://world.openfoodfacts.org") {
                    Link("Title names from Open Food Facts", destination: facts)
                    .spliceFace(.micro)
                    .foregroundStyle(DesignTokens.ink)
                    .underline()
                    .frame(minHeight: SpliceTokens.space(6), alignment: .leading)
                }
            }
            .padding(SpliceTokens.space(2))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DesignTokens.bg)
            .simultaneousGesture(TapGesture().onEnded { searchFocused = false })
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .presentationBackground(DesignTokens.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        desk.cancel()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(minWidth: SpliceTokens.space(6), minHeight: SpliceTokens.space(6))
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close discover")
                    .buttonStyle(InkPressStyle())
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { searchFocused = false }
                        .spliceFace(.body)
                }
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            Image("spl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: SpliceTokens.space(20), maxHeight: SpliceTokens.space(20))
                .clipped()
                .accessibilityHidden(true)
            Text("No titles to stash.")
                .spliceFace(.title)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("The shelf on this device is still here when the search is clear.")
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: SpliceTokens.space(2))
            Button("Show the shelf") {
                searchFocused = false
                desk.edit("")
            }
            .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func message(for error: TitleSearchError) -> String {
        switch error {
        case .notFound:
            return "Nothing matched that search. The shelf on this device is listed below."
        case .transport, .decoding, .malformedURL, .cancelled:
            return "Search did not answer. The shelf on this device is still here."
        }
    }
}

/// Shows a spinner only after the search has already taken 150 ms.
private struct HeldProgress: View {
    var active: Bool
    @State private var visible = false

    var body: some View {
        Group {
            if active && visible {
                ProgressView("Searching titles")
                    .spliceFace(.caption)
                    .tint(DesignTokens.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task(id: active) {
            visible = false
            guard active else { return }
            try? await Task.sleep(nanoseconds: 150_000_000)
            if !Task.isCancelled {
                visible = true
            }
        }
    }
}

/// Live cover for Discover. The sheet stays the search surface.
struct DiscoverView: View {
    @ObservedObject var desk: DiscoverDesk
    var stash: (Stub) -> Void

    var body: some View {
        DiscoverSheet(desk: desk, stash: stash)
    }
}

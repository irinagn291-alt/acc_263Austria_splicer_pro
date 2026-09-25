import SwiftUI

/// Permanent root. The two lanes never push away. Discover, Ash, Profile, and Settings are sheets.
struct BoardRoot: View {
    @ObservedObject var desk: BoardDesk
    @StateObject private var discover = DiscoverDesk()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if desk.chart.fold.phase == .dark {
                DarkEmpty {
                    desk.plate = .discover
                }
            } else {
                board
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.bg.ignoresSafeArea())
        .sheet(item: $desk.plate) { plate in
            switch plate {
            case .discover:
                DiscoverView(desk: discover) { stub in
                    Task { await desk.stash(stub) }
                }
            case .ash:
                AshView(
                    marks: desk.chart.burnMarks,
                    failed: desk.writeFailed || desk.load == .emptyAfterCorruption,
                    retry: { Task { await desk.reload() } }
                )
            case .profile:
                ProfileView(
                    marks: desk.chart.burnMarks,
                    failed: desk.writeFailed || desk.load == .emptyAfterCorruption,
                    retry: { Task { await desk.reload() } }
                )
            case .settings:
                SettingsView {
                    Task { await desk.reopenOnboarding() }
                } reset: {
                    Task { await desk.resetAll() }
                }
            }
        }
        .sheet(item: gradeBinding) { mark in
            GradeSheet(title: mark.title) { stars in
                Task { await desk.grade(stars) }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .laneFoldNotice)) { _ in
            Task { await desk.reload() }
        }
        .task {
            await Task.yield()
            desk.applyReviewIfNeeded()
        }
    }

    private var board: some View {
        VStack(alignment: .leading, spacing: 0) {
            marquee
            if desk.load == .emptyAfterCorruption || desk.writeFailed {
                VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                    Text(desk.load == .emptyAfterCorruption
                         ? "The saved board could not be read. This session started empty."
                         : "The last save did not land. The board on screen is still the one in memory.")
                        .spliceFace(.caption)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Read the board again") {
                        Task { await desk.reload() }
                    }
                    .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
                }
                .padding(SpliceTokens.space(2))
            }
            LaneLayout {
                StackLane(
                    stubs: desk.chart.stack,
                    drawEnabled: desk.chart.gate == nil && !desk.chart.stack.isEmpty,
                    note: desk.laneNote,
                    failed: desk.writeFailed,
                    stash: { desk.plate = .discover },
                    draw: { Task { await desk.draw() } }
                )
                GateLane(
                    gate: desk.chart.gate,
                    burnLoading: desk.burnLoading,
                    burn: { Task { await desk.burn() } }
                )
            }
            .padding(SpliceTokens.space(3))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(reduceMotion ? nil : .easeOut(duration: SpliceTokens.motion), value: desk.chart.gate?.id)
        }
    }

    private var marquee: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            HStack(alignment: .center, spacing: SpliceTokens.space(2)) {
                Image("spl_HeaderDecor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: SpliceTokens.space(12), height: SpliceTokens.space(8))
                    .clipped()
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                    Text("Burn the gate")
                        .spliceFace(.title)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(2)
                    Text(marqueeLine)
                        .spliceFace(.body)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            Rectangle()
                .fill(DesignTokens.muted)
                .frame(height: SpliceTokens.hairline)
                .accessibilityHidden(true)
            HStack(spacing: SpliceTokens.space(1)) {
                chrome("Discover", "magnifyingglass") { desk.plate = .discover }
                chrome("Ash", "list.bullet") { desk.plate = .ash }
                chrome("Profile", "person") { desk.plate = .profile }
                chrome("Settings", "gearshape") { desk.plate = .settings }
            }
        }
        .padding(.horizontal, SpliceTokens.space(2))
        .padding(.vertical, SpliceTokens.space(2))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            DesignTokens.surface
                .overlay(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
        .spliceLift()
    }

    private var marqueeLine: String {
        if let title = desk.chart.gate?.title {
            return "Watch \(title). Burn it when you finish."
        }
        if desk.chart.stack.isEmpty {
            return "Stash a title, then draw it onto the gate."
        }
        return "Draw the top of the stack onto the gate."
    }

    private func chrome(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: SpliceTokens.space(1)) {
                Image(systemName: symbol)
                Text(title)
                    .spliceFace(.micro)
                    .lineLimit(1)
            }
            .foregroundStyle(DesignTokens.ink)
            .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6))
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(title)
    }

    private var gradeBinding: Binding<BurnMark?> {
        Binding(
            get: { desk.pendingGrade },
            set: { desk.pendingGrade = $0 }
        )
    }
}

struct GradeSheet: View {
    var title: String
    var choose: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            Image("spl_SuccessMark")
                .resizable()
                .scaledToFit()
                .frame(width: SpliceTokens.space(10), height: SpliceTokens.space(10))
                .accessibilityHidden(true)
            Text("Rate \(title)")
                .spliceFace(.title)
                .foregroundStyle(DesignTokens.ink)
                .lineLimit(3)
            Text("The grade stays on this burn.")
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.muted)
            HStack(spacing: SpliceTokens.space(1)) {
                ForEach(1...5, id: \.self) { stars in
                    Button {
                        choose(stars)
                    } label: {
                        Text(SpliceFigures.text(stars))
                    }
                    .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
                    .accessibilityLabel("Grade \(SpliceFigures.text(stars))")
                }
            }
            Spacer(minLength: 0)
        }
        .padding(SpliceTokens.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
        .presentationDetents([.medium])
    }
}

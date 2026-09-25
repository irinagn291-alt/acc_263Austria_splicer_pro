import SwiftUI

/// Ash is burn order. It is not a seen journal of titles still on the board.
struct AshSheet: View {
    var marks: [BurnMark]
    var failed: Bool
    var retry: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if marks.isEmpty {
                    empty
                } else {
                    List(marks) { mark in
                        VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                            Text(mark.title)
                                .spliceFace(.headline)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(2)
                            HStack {
                                Text(SpliceFigures.text(mark.day))
                                    .spliceFace(.caption)
                                    .foregroundStyle(DesignTokens.muted)
                                    .monospacedDigit()
                                Spacer()
                                Text(gradeLine(mark.grade))
                                    .spliceFace(.caption)
                                    .foregroundStyle(DesignTokens.ink)
                                    .monospacedDigit()
                            }
                        }
                        .padding(.vertical, SpliceTokens.space(1))
                        .listRowBackground(DesignTokens.surface)
                    }
                    .listStyle(.plain)
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Ash")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(minWidth: SpliceTokens.space(6), minHeight: SpliceTokens.space(6))
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close ash")
                    .buttonStyle(InkPressStyle())
                }
            }
            .safeAreaInset(edge: .top) {
                if failed {
                    VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                        Text("A save failed. Ash is showing the burns still held in memory.")
                            .spliceFace(.caption)
                            .foregroundStyle(DesignTokens.ink)
                        Button("Read the board again", action: retry)
                            .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(SpliceTokens.space(2))
                    .background(DesignTokens.surface)
                }
            }
            .toolbarBackground(DesignTokens.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .presentationBackground(DesignTokens.bg)
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            Image("spl_EmptyList")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: SpliceTokens.space(24), maxHeight: SpliceTokens.space(24))
                .clipped()
                .accessibilityHidden(true)
            Text("No burns yet.")
                .spliceFace(.display)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Finish the title on the gate and burn it. Ash keeps that order on this device.")
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                Text("Burn order")
                    .spliceFace(.caption)
                    .foregroundStyle(DesignTokens.muted)
                Text("Each finish is written once, then the gate clears. The stack is not listed here.")
                    .spliceFace(.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(SpliceTokens.space(2))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignTokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.laneRadius, style: .continuous))
            .spliceLift()
            Spacer(minLength: SpliceTokens.space(2))
            Button("Return to the gate") { dismiss() }
                .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
        }
        .padding(SpliceTokens.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func gradeLine(_ grade: SpliceGrade?) -> String {
        guard let grade else { return "Unrated" }
        let figure = SpliceFigures.text(grade.stars)
        return "Grade \(figure)"
    }
}

/// Live cover for Ash. Burn marks stay in burn order.
struct AshView: View {
    var marks: [BurnMark]
    var failed: Bool
    var retry: () -> Void

    var body: some View {
        AshSheet(marks: marks, failed: failed, retry: retry)
    }
}

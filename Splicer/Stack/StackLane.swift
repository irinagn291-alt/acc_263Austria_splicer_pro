import SwiftUI

/// Stack lane. Stash and Draw fuse here. Heights stay uneven so the pile is not a uniform list.
struct StackLane: View {
    var stubs: [Stub]
    var drawEnabled: Bool
    var note: String
    var failed: Bool
    var stash: () -> Void
    var draw: () -> Void


    var body: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
            Text("Stack")
                .spliceFace(.caption)
                .foregroundStyle(DesignTokens.muted)
            Text(SpliceFigures.text(stubs.count))
                .spliceFace(.title)
                .foregroundStyle(DesignTokens.ink)
                .monospacedDigit()
                .accessibilityLabel("\(SpliceFigures.text(stubs.count)) titles on the stack")
            if failed {
                Text("The last save did not land. The pile on screen is still the one in memory.")
                    .spliceFace(.micro)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if stubs.isEmpty {
                Text("The stack is empty.")
                    .spliceFace(.caption)
                    .foregroundStyle(DesignTokens.muted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                        ForEach(Array(stubs.enumerated()), id: \.element.id) { index, stub in
                            Text(stub.title)
                                .spliceFace(.caption)
                                .foregroundStyle(DesignTokens.ink)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, minHeight: height(for: index), alignment: .topLeading)
                                .overlay(alignment: .bottom) {
                                    Rectangle()
                                        .fill(DesignTokens.muted)
                                        .frame(height: SpliceTokens.hairline)
                                }
                        }
                    }
                }
            }
            if !note.isEmpty {
                Text(note)
                    .spliceFace(.micro)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(action: stash) {
                Label("Stash", systemImage: "plus")
                    .spliceFace(.caption)
                    .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .tint(DesignTokens.ink)
            .accessibilityLabel("Stash a title")
            Button(action: draw) {
                Label("Draw", systemImage: "arrow.right")
                    .spliceFace(.caption)
                    .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.bordered)
            .tint(DesignTokens.ink)
            .disabled(!drawEnabled)
            .accessibilityLabel("Draw the top title")
            .accessibilityHint(drawEnabled ? "Moves the top stack title onto the gate." : "Draw waits until the gate is clear and the stack has a title.")
        }
        .padding(SpliceTokens.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.laneRadius, style: .continuous))
        .spliceLift()
    }

    private func height(for index: Int) -> CGFloat {
        let steps: [CGFloat] = [9, 7, 11, 8]
        return SpliceTokens.space(steps[index % steps.count])
    }
}

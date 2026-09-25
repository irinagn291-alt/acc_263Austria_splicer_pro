import SwiftUI

/// Profile counts burns and the grades folded onto them. It does not list the stack.
struct ProfileSheet: View {
    var marks: [BurnMark]
    var failed: Bool
    var retry: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if failed && marks.isEmpty {
                    errorPage
                } else if marks.isEmpty {
                    empty
                } else {
                    populated
                }
            }
            .background(DesignTokens.bg)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DesignTokens.bg, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .presentationBackground(DesignTokens.bg)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(minWidth: SpliceTokens.space(6), minHeight: SpliceTokens.space(6))
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Close profile")
                    .buttonStyle(InkPressStyle())
                }
            }
        }
    }

    private var populated: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SpliceTokens.space(3)) {
                if failed {
                    VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                        Text("A save failed. These counts are the burns still held in memory.")
                            .spliceFace(.caption)
                            .foregroundStyle(DesignTokens.ink)
                        Button("Read the board again", action: retry)
                            .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
                    }
                }
                Text("Burns")
                    .spliceFace(.caption)
                    .foregroundStyle(DesignTokens.muted)
                Text(SpliceFigures.text(marks.count))
                    .spliceFace(.display)
                    .foregroundStyle(DesignTokens.ink)
                    .monospacedDigit()
                Text("Grades stay on the burn. The stack is not part of this count.")
                    .spliceFace(.body)
                    .foregroundStyle(DesignTokens.muted)
                VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                    ForEach(1...5, id: \.self) { stars in
                        HStack {
                            let figure = SpliceFigures.text(stars)
                            Text("Grade \(figure)")
                                .spliceFace(.body)
                                .foregroundStyle(DesignTokens.ink)
                            Spacer()
                            Text(SpliceFigures.text(count(stars)))
                                .spliceFace(.headline)
                                .foregroundStyle(DesignTokens.ink)
                                .monospacedDigit()
                        }
                        .frame(minHeight: SpliceTokens.space(6))
                    }
                }
                .padding(SpliceTokens.space(2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.surface)
                .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.laneRadius, style: .continuous))
            }
            .padding(SpliceTokens.space(3))
            .frame(maxWidth: .infinity, alignment: .leading)
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
            Text("No grades yet.")
                .spliceFace(.display)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Burn the gate, then rate it. Profile only reads those marks.")
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            VStack(alignment: .leading, spacing: SpliceTokens.space(1)) {
                Text("What a grade is")
                    .spliceFace(.caption)
                    .foregroundStyle(DesignTokens.muted)
                Text("A grade is a whole number from 1 to 5, written on the burn and kept on this device.")
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

    private var errorPage: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            Text("Profile could not read a saved chart.")
                .spliceFace(.title)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("The last write failed and there is no burn count to show.")
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: SpliceTokens.space(2))
            Button("Read the board again", action: retry)
                .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
        }
        .padding(SpliceTokens.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func count(_ stars: Int) -> Int {
        marks.filter { $0.grade?.stars == stars }.count
    }
}

/// Live cover for Profile. Counts and grades only.
struct ProfileView: View {
    var marks: [BurnMark]
    var failed: Bool
    var retry: () -> Void

    var body: some View {
        ProfileSheet(marks: marks, failed: failed, retry: retry)
    }
}

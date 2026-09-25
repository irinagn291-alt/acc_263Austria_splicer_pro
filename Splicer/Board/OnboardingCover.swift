import SwiftUI

/// Three pages, then a completion flag. Skip writes the same defaults as finishing.
struct OnboardingCover: View {
    var finish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0

    var body: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            HStack {
                Spacer()
                Button("Skip") { finish() }
                    .spliceFace(.body)
                    .foregroundStyle(DesignTokens.ink)
                    .frame(minHeight: SpliceTokens.space(6))
                    .contentShape(Rectangle())
                    .buttonStyle(InkPressStyle())
            }
            Group {
                switch page {
                case 0:
                    pageBody(
                        image: "spl_Onboarding1",
                        title: "Keep one title on the gate.",
                        line: "Splicer is a watch pile for this device. You stash titles, then burn them one at a time."
                    )
                case 1:
                    pageBody(
                        image: "spl_Onboarding2",
                        title: "Draw, then burn.",
                        line: "Draw moves the top of the stack onto the gate. Burn writes the finish and takes that title off the board."
                    )
                default:
                    pageBody(
                        image: "spl_Onboarding3",
                        title: "Ash keeps the order.",
                        line: "Rate each burn from 1 to 5. Profile reads those grades and nothing else."
                    )
                }
            }
            .animation(reduceMotion ? nil : .easeOut(duration: SpliceTokens.motion), value: page)
            Button(action: advance) {
                Text(page >= 2 ? "Continue" : "Next")
            }
            .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
        }
        .padding(SpliceTokens.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
    }

    private func advance() {
        if page >= 2 {
            finish()
        } else {
            page += 1
        }
    }

    private func pageBody(image: String, title: String, line: String) -> some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            Image(image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: SpliceTokens.space(40))
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .spliceFace(.display)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(line)
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

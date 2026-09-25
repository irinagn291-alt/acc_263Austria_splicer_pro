import SwiftUI

/// Full-page empty board. One headline, one line, one stash control.
struct DarkEmpty: View {
    var stash: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            Spacer(minLength: SpliceTokens.space(2))
            Image("spl_EmptyHome")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: SpliceTokens.space(28), maxHeight: SpliceTokens.space(28))
                .accessibilityHidden(true)
            Text("Nothing is on the board.")
                .spliceFace(.display)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Stash a title on the stack, then draw it onto the gate when you are ready to watch.")
                .spliceFace(.body)
                .foregroundStyle(DesignTokens.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: SpliceTokens.space(2))
            Button(action: stash) {
                Text("Stash a title")
            }
            .buttonStyle(BurnChromeStyle(loading: false, enabled: true))
            .accessibilityHint("Opens search so you can place a title on the stack.")
        }
        .padding(SpliceTokens.space(3))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(DesignTokens.bg)
    }
}

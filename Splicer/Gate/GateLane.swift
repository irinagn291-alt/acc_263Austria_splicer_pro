import SwiftUI

/// Gate is the hero. Burn fuses here and stays disabled until a stub is seated.
struct GateLane: View {
    var gate: Stub?
    var burnLoading: Bool
    var burn: () -> Void

    @ScaledMetric(relativeTo: .largeTitle) private var heroFloor: CGFloat = SpliceTokens.space(15)

    var body: some View {
        VStack(alignment: .leading, spacing: SpliceTokens.space(2)) {
            HStack {
                Text("Gate")
                    .spliceFace(.caption)
                    .foregroundStyle(DesignTokens.muted)
                Spacer()
                Text(gate == nil ? "Open" : "Seated")
                    .spliceFace(.micro)
                    .foregroundStyle(DesignTokens.ink)
                    .padding(.horizontal, SpliceTokens.space(1))
                    .padding(.vertical, SpliceTokens.space(1))
                    .background(DesignTokens.bg)
                    .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous))
            }
            if let gate {
                HStack(alignment: .top, spacing: SpliceTokens.space(2)) {
                    Text(gate.title)
                        .spliceFace(.display)
                        .foregroundStyle(DesignTokens.ink)
                        .lineLimit(4)
                        .frame(maxWidth: .infinity, minHeight: heroFloor, alignment: .topLeading)
                    Image("spl_TwistHero")
                        .resizable()
                        .scaledToFit()
                        .frame(width: SpliceTokens.space(12), height: SpliceTokens.space(12))
                        .clipped()
                        .accessibilityHidden(true)
                }
                Text("This is the title you are watching. Burn it when you finish.")
                    .spliceFace(.body)
                    .foregroundStyle(DesignTokens.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No title is seated.")
                    .spliceFace(.title)
                    .foregroundStyle(DesignTokens.ink)
                    .frame(maxWidth: .infinity, minHeight: heroFloor, alignment: .topLeading)
                Text("Draw the top of the stack onto the gate.")
                    .spliceFace(.body)
                    .foregroundStyle(DesignTokens.muted)
            }
            Spacer(minLength: SpliceTokens.space(1))
            Button(action: burn) {
                Text(burnLoading ? "Burning" : "Burn the gate")
                    .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6))
                    .contentShape(Rectangle())
                    .opacity(burnLoading ? 0 : 1)
            }
            .buttonStyle(BurnChromeStyle(loading: burnLoading, enabled: gate != nil && !burnLoading))
            .disabled(gate == nil || burnLoading)
            .accessibilityLabel("Burn the gate")
            .accessibilityHint(gate == nil ? "Draw a title onto the gate first." : "Writes a burn and removes the title from the board.")
        }
        .padding(SpliceTokens.space(2))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignTokens.surface)
        .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.laneRadius, style: .continuous))
        .spliceLift()
    }
}

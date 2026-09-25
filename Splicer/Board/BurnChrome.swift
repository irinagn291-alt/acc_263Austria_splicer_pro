import SwiftUI

/// Bordered prominent burn control. Default, pressed, disabled, and loading.
struct BurnChromeStyle: ButtonStyle {
    var loading: Bool
    var enabled: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .spliceFace(.headline)
            .foregroundStyle(enabled ? DesignTokens.ink : DesignTokens.muted)
            .frame(maxWidth: .infinity, minHeight: SpliceTokens.space(6))
            .background {
                RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous)
                    .fill(enabled && !loading ? DesignTokens.accent : DesignTokens.surface)
                    .overlay {
                        if configuration.isPressed && enabled && !loading {
                            DesignTokens.bg.opacity(0.28)
                        }
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous)
                    .strokeBorder(enabled ? DesignTokens.accent : DesignTokens.muted, lineWidth: SpliceTokens.hairline)
            }
            .overlay {
                if loading {
                    ProgressView()
                        .tint(DesignTokens.ink)
                }
            }
            .opacity(pressedOpacity(configuration.isPressed))
            .scaleEffect(pressedScale(configuration.isPressed))
            .contentShape(RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous))
            .animation(reduceMotion ? nil : .easeOut(duration: SpliceTokens.motion), value: configuration.isPressed)
    }

    private func pressedOpacity(_ pressed: Bool) -> Double {
        if loading { return 0.72 }
        return pressed && enabled ? 0.88 : 1
    }

    private func pressedScale(_ pressed: Bool) -> CGFloat {
        guard enabled, pressed, !loading, !reduceMotion else { return 1 }
        return 0.98
    }

}

/// Destructive release and reset. Accent is never the delete colour.
struct ReleaseChromeStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .spliceFace(.caption)
            .foregroundStyle(DesignTokens.ink)
            .frame(minHeight: SpliceTokens.space(6))
            .padding(.horizontal, SpliceTokens.space(2))
            .background(configuration.isPressed ? DesignTokens.bg : DesignTokens.surface)
            .clipShape(RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous)
                    .strokeBorder(DesignTokens.muted, lineWidth: SpliceTokens.hairline)
            }
            .contentShape(RoundedRectangle(cornerRadius: SpliceTokens.chipRadius, style: .continuous))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

/// Pressed ink for icon chrome. Not a second elevation.
struct InkPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.62 : 1)
            .contentShape(Rectangle())
    }
}

import SwiftUI

/// Spacing, type, radius, and the one elevation. Colour stays on DesignTokens.
enum SpliceTokens {
    static let unit: CGFloat = 8
    static let laneRadius: CGFloat = 24
    static let chipRadius: CGFloat = 10
    static let motion: Double = 0.18
    static let hairline: CGFloat = 1

    static func space(_ steps: CGFloat) -> CGFloat { unit * steps }

    static let shadowColor = Color.black.opacity(0.28)
    static let shadowRadius: CGFloat = 16
    static let shadowY: CGFloat = 8

    enum Step {
        case display
        case title
        case headline
        case body
        case caption
        case micro

        var points: CGFloat {
            switch self {
            case .display: return 34
            case .title: return 28
            case .headline: return 22
            case .body: return 17
            case .caption: return 13
            case .micro: return 11
            }
        }

        var bold: Bool {
            switch self {
            case .display, .title, .headline: return true
            case .body, .caption, .micro: return false
            }
        }
    }

    /// `size` comes from ScaledMetric. Accessibility sizes use New York so hairline serifs stay readable.
    static func font(_ step: Step, dynamic: DynamicTypeSize, size: CGFloat? = nil) -> Font {
        let resolved = min(size ?? step.points, 34)
        if dynamic.isAccessibilitySize {
            return Font.custom("New York", size: resolved)
        }
        let name = step.bold ? "Bodoni 72 Bold" : "Bodoni 72 Book"
        if size == nil {
            return Font.custom(name, size: resolved, relativeTo: textStyle(step))
        }
        return Font.custom(name, size: resolved)
    }

    private static func textStyle(_ step: Step) -> Font.TextStyle {
        switch step {
        case .display: return .largeTitle
        case .title: return .title
        case .headline: return .headline
        case .body: return .body
        case .caption: return .caption
        case .micro: return .caption2
        }
    }
}

private struct SpliceFace: ViewModifier {
    var step: SpliceTokens.Step
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var display: CGFloat = 34
    @ScaledMetric(relativeTo: .title) private var title: CGFloat = 28
    @ScaledMetric(relativeTo: .headline) private var headline: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17
    @ScaledMetric(relativeTo: .caption) private var caption: CGFloat = 13
    @ScaledMetric(relativeTo: .caption2) private var micro: CGFloat = 11

    func body(content: Content) -> some View {
        content.font(SpliceTokens.font(step, dynamic: dynamicTypeSize, size: points))
    }

    private var points: CGFloat {
        let raw: CGFloat
        switch step {
        case .display: raw = display
        case .title: raw = title
        case .headline: raw = headline
        case .body: raw = bodySize
        case .caption: raw = caption
        case .micro: raw = micro
        }
        return min(raw, 34)
    }
}

extension View {
    func spliceFace(_ step: SpliceTokens.Step) -> some View {
        modifier(SpliceFace(step: step))
    }

    func spliceLift() -> some View {
        shadow(
            color: SpliceTokens.shadowColor,
            radius: SpliceTokens.shadowRadius,
            x: 0,
            y: SpliceTokens.shadowY
        )
    }
}

@MainActor
enum SpliceFigures {
    static let plain: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        return formatter
    }()

    static func text(_ value: Int) -> String {
        plain.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}

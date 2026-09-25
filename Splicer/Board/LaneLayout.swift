import SwiftUI

/// The one custom surface. Stack sits in a narrow column. Gate takes the remaining width.
struct LaneLayout: Layout {
    var gap: CGFloat = SpliceTokens.space(1)

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let height = proposal.height ?? SpliceTokens.space(40)
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count >= 2 else { return }
        let stackWidth = max(SpliceTokens.space(14), bounds.width * 0.34)
        let gateWidth = max(0, bounds.width - stackWidth - gap)
        subviews[0].place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            proposal: ProposedViewSize(width: stackWidth, height: bounds.height)
        )
        subviews[1].place(
            at: CGPoint(x: bounds.minX + stackWidth + gap, y: bounds.minY),
            proposal: ProposedViewSize(width: gateWidth, height: bounds.height)
        )
    }
}

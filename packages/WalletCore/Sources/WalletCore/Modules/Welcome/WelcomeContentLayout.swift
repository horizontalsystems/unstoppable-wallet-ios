import SwiftUI

/// Places the text block (subview 0) at the centre of the full screen and the buttons block (subview 1) at the bottom of the container.
/// The container occupies the safe area; the text block is kept above the buttons block and below the top of the safe area.
struct WelcomeContentLayout: Layout {
    private let safeAreaInsets: EdgeInsets

    init(safeAreaInsets: EdgeInsets) {
        self.safeAreaInsets = safeAreaInsets
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews _: Subviews, cache _: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        guard subviews.count == 2 else {
            return
        }

        let width = ProposedViewSize(width: bounds.width, height: nil)

        let buttonsSize = subviews[1].sizeThatFits(width)
        subviews[1].place(at: CGPoint(x: bounds.minX, y: bounds.maxY), anchor: .bottomLeading, proposal: width)

        let textSize = subviews[0].sizeThatFits(width)
        let centerY = bounds.midY + (safeAreaInsets.bottom - safeAreaInsets.top) / 2

        var top = centerY - textSize.height / 2
        top = min(top, bounds.maxY - buttonsSize.height - textSize.height)
        top = max(top, bounds.minY)

        subviews[0].place(at: CGPoint(x: bounds.minX, y: top), anchor: .topLeading, proposal: width)
    }
}

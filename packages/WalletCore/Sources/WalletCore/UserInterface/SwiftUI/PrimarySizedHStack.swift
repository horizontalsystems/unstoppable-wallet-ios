import SwiftUI

struct PrimarySizedHStack<Primary: View, Trailing: View>: View {
    let spacing: CGFloat
    @ViewBuilder let primary: Primary
    @ViewBuilder let trailing: Trailing

    init(spacing: CGFloat = .margin16, @ViewBuilder primary: () -> Primary, @ViewBuilder trailing: () -> Trailing) {
        self.spacing = spacing
        self.primary = primary()
        self.trailing = trailing()
    }

    var body: some View {
        PrimarySizedHStackLayout(spacing: spacing) {
            primary
                .frame(maxWidth: .infinity, alignment: .leading)

            trailing
        }
    }
}

extension PrimarySizedHStack where Trailing == EmptyView {
    init(spacing: CGFloat = .margin16, @ViewBuilder primary: () -> Primary) {
        self.spacing = spacing
        self.primary = primary()
        trailing = EmptyView()
    }
}

private struct PrimarySizedHStackLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let trailingWidth = trailingSize(subviews: subviews).width
        let primarySize = subviews.first?.sizeThatFits(primaryProposal(proposal, trailingWidth: trailingWidth)) ?? .zero

        return CGSize(
            width: proposal.width ?? primarySize.width + reserve(for: trailingWidth),
            height: primarySize.height
        )
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let trailingSize = trailingSize(subviews: subviews)

        subviews.first?.place(
            at: CGPoint(x: bounds.minX, y: bounds.minY),
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: max(0, bounds.width - reserve(for: trailingSize.width)),
                height: bounds.height
            )
        )

        guard trailingSize.width > 0, subviews.indices.contains(1) else {
            return
        }

        subviews[1].place(
            at: CGPoint(x: bounds.maxX, y: bounds.midY),
            anchor: .trailing,
            proposal: ProposedViewSize(trailingSize)
        )
    }

    private func trailingSize(subviews: Subviews) -> CGSize {
        guard subviews.indices.contains(1) else {
            return .zero
        }
        return subviews[1].sizeThatFits(.unspecified)
    }

    private func primaryProposal(_ proposal: ProposedViewSize, trailingWidth: CGFloat) -> ProposedViewSize {
        ProposedViewSize(
            width: proposal.width.map { max(0, $0 - reserve(for: trailingWidth)) },
            height: proposal.height
        )
    }

    private func reserve(for trailingWidth: CGFloat) -> CGFloat {
        trailingWidth > 0 ? trailingWidth + spacing : 0
    }
}

import SwiftUI

struct CenteredFlowLayout: Layout {
    private let itemSpacing: CGFloat
    private let lineSpacing: CGFloat

    init(itemSpacing: CGFloat = .margin16, lineSpacing: CGFloat = .margin16) {
        self.itemSpacing = itemSpacing
        self.lineSpacing = lineSpacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let proposedWidth = proposal.width.flatMap { $0.isFinite ? $0 : nil }
        let maxWidth = proposedWidth ?? sizes.reduce(0) { $0 + $1.width } + itemSpacing * CGFloat(max(sizes.count - 1, 0))
        let lines = Self.lines(sizes: sizes, maxWidth: maxWidth, itemSpacing: itemSpacing)

        guard !lines.isEmpty else {
            return CGSize(width: proposedWidth ?? 0, height: 0)
        }

        let height = lines.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(lines.count - 1)
        let width = proposedWidth ?? (lines.map(\.width).max() ?? 0)

        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let lines = Self.lines(sizes: sizes, maxWidth: bounds.width, itemSpacing: itemSpacing)

        var y = bounds.minY

        for line in lines {
            var x = bounds.minX + max(0, (bounds.width - line.width) / 2)

            for index in line.indices {
                let size = sizes[index]
                let itemWidth = min(size.width, bounds.width)

                subviews[index].place(
                    at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: itemWidth, height: size.height)
                )

                x += itemWidth + itemSpacing
            }

            y += line.height + lineSpacing
        }
    }

    private static func lines(sizes: [CGSize], maxWidth: CGFloat, itemSpacing: CGFloat) -> [Line] {
        var lines = [Line]()
        var current = Line()

        for (index, size) in sizes.enumerated() {
            let itemWidth = min(size.width, maxWidth)
            let widthWithItem = current.indices.isEmpty ? itemWidth : current.width + itemSpacing + itemWidth

            if !current.indices.isEmpty, widthWithItem > maxWidth {
                lines.append(current)
                current = Line()
                current.indices = [index]
                current.width = itemWidth
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = widthWithItem
                current.height = max(current.height, size.height)
            }
        }

        if !current.indices.isEmpty {
            lines.append(current)
        }

        return lines
    }
}

extension CenteredFlowLayout {
    private struct Line {
        var indices = [Int]()
        var width: CGFloat = 0
        var height: CGFloat = 0
    }
}

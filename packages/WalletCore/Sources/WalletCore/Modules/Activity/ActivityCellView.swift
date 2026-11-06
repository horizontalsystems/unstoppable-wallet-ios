import SwiftUI

/// A row of the Activity lists. Each row lays out its own top border, and the last row of a section also its bottom one,
/// so the section headers carry no line. The borders are stacked with the cell, as `ListForEach` does, so each is one
/// physical pixel on a pixel boundary.
struct ActivityCellView: View {
    private let viewItem: ActivityCellViewItem
    private let isLast: Bool
    private let action: () -> Void

    init(viewItem: ActivityCellViewItem, isLast: Bool = false, action: @escaping () -> Void) {
        self.viewItem = viewItem
        self.isLast = isLast
        self.action = action
    }

    private var opacity: Double {
        viewItem.dimmed ? 0.25 : 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HorizontalDivider()

            Cell(
                left: { glyphView },
                middle: { middleView },
                right: { rightView },
                action: action
            )

            if isLast {
                HorizontalDivider()
            }
        }
    }

    private var glyphView: some View {
        ZStack {
            if viewItem.state.showsRing {
                PendingLoaderRing()
            }

            ThemeImage(viewItem.glyph, size: .iconSize24, colorStyle: viewItem.state.glyphColorStyle)
        }
        .frame(width: .iconSize40, height: .iconSize40)
        .opacity(opacity)
    }

    private var middleView: some View {
        VStack(alignment: .leading, spacing: .heightOneDp) {
            titleRow

            subtitleView
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(opacity)
    }

    /// While pending, the subtitle fades andy → gray → andy once per ring turn: a gray layer over an andy one,
    /// its opacity read from the ring's clock. `TimelineView` stops updating when the row is not drawn.
    @ViewBuilder private var subtitleView: some View {
        if viewItem.state.showsRing {
            TimelineView(.animation) { timeline in
                ZStack(alignment: .leading) {
                    subtitleText(colorStyle: .andy)
                    subtitleText(colorStyle: .secondary)
                        .opacity(PendingAnimation.phase(date: timeline.date))
                        .accessibilityHidden(true)
                }
            }
        } else {
            subtitleText(colorStyle: viewItem.state.subtitleColorStyle)
        }
    }

    private func subtitleText(colorStyle: ColorStyle) -> some View {
        ThemeText(viewItem.subtitle, style: .subhead, colorStyle: colorStyle)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    private var titleRow: some View {
        HStack(spacing: .margin4) {
            ForEach(Array(viewItem.tokens.enumerated()), id: \.offset) { index, token in
                if index > 0 {
                    ThemeImage("arrow_m_right", size: .iconSize16, colorStyle: .secondary)
                }

                tokenIcon(token.icon)

                ThemeText(token.text, style: .headline2, colorStyle: token.isUnknown ? .andy : nil)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if viewItem.doubleSpend {
                ThemeImage("double_send", size: .iconSize16)
            }

            if let locked = viewItem.locked {
                Image.lock(unlocked: !locked, size: .iconSize16)
            }
        }
    }

    @ViewBuilder private func tokenIcon(_ icon: ActivityCellViewItem.Token.Icon) -> some View {
        switch icon {
        case let .remote(url, alternativeUrl, placeholder, type):
            IconView(url: url, alternativeUrl: alternativeUrl, placeholderImage: placeholder, type: type, size: .iconSize16)
        case let .local(name):
            // the chain glyphs are single-colour PNGs, tinted as the row's former chain icon was
            ThemeImage(name, size: .iconSize16, colorStyle: .primary)
        case .unknown:
            // the Blade circle `IconView` shows for a coin without a logo
            ThemeImage(ComponentImage(image: "placeholder_circle", contentMode: .fit), size: .size16)
        }
    }

    @ViewBuilder private var rightView: some View {
        let primaryValue = viewItem.primaryValue.flatMap { $0.text.isEmpty ? nil : $0 }
        let secondaryValue = viewItem.secondaryValue.flatMap { $0.text.isEmpty ? nil : $0 }

        if primaryValue != nil || secondaryValue != nil {
            VStack(alignment: .trailing, spacing: .heightOneDp) {
                if let primaryValue {
                    ThemeText(primaryValue.text, style: .headline2, colorStyle: viewItem.primaryValueColorStyle)
                        .lineLimit(1)
                }

                if let secondaryValue {
                    ThemeText(secondaryValue.text, style: .subheadSB, colorStyle: viewItem.secondaryValueColorStyle)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
            .opacity(opacity)
        }
    }
}

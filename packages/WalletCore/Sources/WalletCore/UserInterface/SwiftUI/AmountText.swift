import SwiftUI

struct AmountText<Trailing: View>: View {
    private static var minimumTitleScale: CGFloat {
        0.25
    }

    let title: CustomStringConvertible
    var subtitle: CustomStringConvertible?
    var identifier: String?
    var subtitleIdentifier: String?
    var onTapTitle: (() -> Void)?
    var onTapSubtitle: (() -> Void)?
    @ViewBuilder let subtitleTrailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleView

            if let subtitle {
                PrimarySizedHStack(spacing: .margin8) {
                    subtitleText(subtitle: subtitle)
                } trailing: {
                    subtitleTrailing()
                }
            }
        }
        .identified(identifier)
        .padding(.horizontal, .margin16)
        .padding(.vertical, .margin24)
    }

    /// The hidden full-size line pins the row height, so a shrunk title does not move the content below it,
    /// and the title stays on the full-size baseline when it shrinks.
    private var titleView: some View {
        ThemeText(" ", style: .title)
            .hidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .leadingLastTextBaseline) {
                ThemeText(title, style: .title)
                    .lineLimit(1)
                    .minimumScaleFactor(Self.minimumTitleScale)
            }
            .contentShape(Rectangle())
            .tappable(action: onTapTitle)
    }

    private func subtitleText(subtitle: CustomStringConvertible) -> some View {
        ThemeText(subtitle, style: .body, colorStyle: .secondary)
            .multilineTextAlignment(.leading)
            .tappable(action: onTapSubtitle)
            .withIdentifier(subtitleIdentifier)
    }
}

extension AmountText where Trailing == EmptyView {
    init(
        title: CustomStringConvertible,
        subtitle: CustomStringConvertible? = nil,
        identifier: String? = nil,
        subtitleIdentifier: String? = nil,
        onTapTitle: (() -> Void)? = nil,
        onTapSubtitle: (() -> Void)? = nil
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            identifier: identifier,
            subtitleIdentifier: subtitleIdentifier,
            onTapTitle: onTapTitle,
            onTapSubtitle: onTapSubtitle,
            subtitleTrailing: { EmptyView() }
        )
    }
}

private extension View {
    @ViewBuilder func tappable(action: (() -> Void)?) -> some View {
        if let action {
            onTapGesture(perform: action)
        } else {
            self
        }
    }

    @ViewBuilder func identified(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityElement(children: .contain)
                .accessibilityIdentifier(identifier)
        } else {
            self
        }
    }

    @ViewBuilder func withIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}

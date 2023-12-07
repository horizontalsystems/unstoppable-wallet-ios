import Kingfisher
import SwiftUI

struct BottomSheetView: View {
    private let icon: Icon?
    private let title: String
    private let titleColor: Color
    private let subtitle: String?

    private let items: [Item]
    private let buttons: [ButtonItem]

    var onDismiss: (() -> Void)?

    init(icon: Icon? = nil, title: String, titleColor: Color = .themeLeah, subtitle: String? = nil, items: [Item] = [], buttons: [ButtonItem] = [], onDismiss: (() -> Void)?) {
        self.icon = icon
        self.title = title
        self.titleColor = titleColor
        self.subtitle = subtitle
        self.items = items
        self.buttons = buttons
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                if let icon {
                    iconView(icon: icon)
                }

                VStack(spacing: 1) {
                    if let subtitle {
                        Text(title).themeBody(color: titleColor)
                        Text(subtitle).themeSubhead2()
                    } else {
                        Text(title).themeHeadline2(color: titleColor)
                    }
                }

                Button(
                    action: { onDismiss?() },
                    label: { Image("close_3_24") }
                )
            }
            .padding(.horizontal, .margin32)
            .padding(.vertical, .margin24)

            VStack(spacing: .margin24) {
                if !items.isEmpty {
                    VStack(spacing: .margin12) {
                        ForEach(items.indices, id: \.self) { index in
                            itemView(item: items[index])
                        }
                    }
                }

                if !buttons.isEmpty {
                    VStack(spacing: .margin12) {
                        ForEach(buttons.indices, id: \.self) { index in
                            buttonView(item: buttons[index])
                        }
                    }
                    .padding(.horizontal, .margin24)
                }
            }
        }
        .padding(.bottom, .margin24)
    }

    @ViewBuilder private func iconView(icon: Icon) -> some View {
        switch icon {
        case let .local(name, tint):
            if let tint {
                Image(name)
                    .themeIcon(color: tint)
                    .frame(width: .iconSize24, height: .iconSize24)
            } else {
                Image(name)
                    .frame(width: .iconSize24, height: .iconSize24)
            }
        case let .remote(url: url, placeholder: placeholder):
            KFImage.url(URL(string: url))
                .resizable()
                .placeholder {
                    if let placeholder {
                        Image(placeholder)
                    } else {
                        RoundedRectangle(cornerRadius: .cornerRadius8, style: .continuous).fill(Color.themeSteel20)
                    }
                }
                .frame(width: .iconSize24, height: .iconSize24)
        }
    }

    @ViewBuilder private func itemView(item: Item) -> some View {
        switch item {
        case let .text(text):
            Text(text)
                .themeBody(color: .themeBran)
                .padding(.horizontal, .margin32)
                .padding(.bottom, .margin32)
        case let .highlightedDescription(text, style):
            HighlightedTextView(text: text, style: style)
                .padding(.horizontal, .margin16)
        }
    }

    @ViewBuilder private func buttonView(item: ButtonItem) -> some View {
        Button(
            action: { item.action?() },
            label: {
                HStack(spacing: .margin8) {
                    if let icon = item.icon {
                        Image(icon).renderingMode(.template)
                    }

                    Text(item.title)
                }
            }
        )
        .buttonStyle(PrimaryButtonStyle(style: item.style))
    }
}

extension BottomSheetView {
    enum Icon {
        case local(name: String, tint: Color? = nil)
        case remote(url: String, placeholder: String?)

        static let warning: Self = .local(name: "warning_2_24", tint: .themeJacob)
        static let info: Self = .local(name: "circle_information_24", tint: .themeGray)
        static let trash: Self = .local(name: "trash_24", tint: .themeLucian)
    }

    enum Item {
        case text(text: String)
        case highlightedDescription(text: String, style: HighlightedTextView.Style = .warning)
    }

    struct ButtonItem {
        let style: PrimaryButtonStyle.Style
        let title: String
        let icon: String?
        let action: (() -> Void)?

        init(style: PrimaryButtonStyle.Style, title: String, icon: String? = nil, action: (() -> Void)? = nil) {
            self.style = style
            self.title = title
            self.icon = icon
            self.action = action
        }
    }
}

struct InfoDescription: Identifiable {
    let title: String
    let description: String

    var id: String {
        title + description
    }
}

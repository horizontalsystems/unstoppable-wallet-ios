import Kingfisher
import SwiftUI

struct AlertView: View {
    private let image: BottomSheetTitleView.Image?
    private let title: String
    private let subtitle: String?

    private let items: [BottomSheetModule.Item]
    private let buttons: [BottomSheetModule.Button]

    var onDismiss: (() -> Void)?

    init(image: BottomSheetTitleView.Image? = nil, title: String, subtitle: String? = nil, items: [BottomSheetModule.Item] = [], buttons: [BottomSheetModule.Button] = [], onDismiss: (() -> Void)?) {
        self.image = image
        self.title = title
        self.subtitle = subtitle
        self.items = items
        self.buttons = buttons
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: .margin16) {
                if let image {
                    image.view()
                }

                VStack(spacing: 1) {
                    if let subtitle {
                        Text(title).themeBody()
                        Text(subtitle).themeSubhead2()
                    } else {
                        Text(title).themeHeadline2()
                    }
                }

                Button(
                    action: { onDismiss?() },
                    label: { Image("close_3_24") }
                )
            }
            .padding(.horizontal, .margin8)

            if !items.isEmpty {
                Spacer().frame(height: .margin24)

                VStack(spacing: .margin12) {
                    ForEach(items, id: \.id) { item in
                        itemView(item: item)
                    }
                }
            }

            if !buttons.isEmpty {
                Spacer().frame(height: .margin24)

                VStack(spacing: .margin12) {
                    ForEach(buttons, id: \.id) { button in
                        Button(
                            action: { button.action?() },
                            label: { Text(button.title) }
                        )
                        .buttonStyle(PrimaryButtonStyle(style: .init(style: button.style)))
                    }
                }
                .padding(.horizontal, .margin24)
            }
        }
        .padding(.margin24)
    }

    @ViewBuilder
    private func itemView(item: BottomSheetModule.Item) -> some View {
        switch item {
        case let .description(text):
            Text(text).themeBody(color: .themeBran)
        case let .highlightedDescription(text, style):
            HighlightedTextView(text: text, style: style)
        case let .copyableValue(title, value):
            HStack(spacing: .margin12) {
                Text(title).themeBody()
                Button(
                    action: { CopyHelper.copyAndNotify(value: value) },
                    label: { Text(value) }
                ).buttonStyle(SecondaryButtonStyle())
            }
        case let .contractAddress(url, value, explorerUrl):
            HStack(spacing: .margin12) {
                KFImage.url(URL(string: url))
                    .resizable()
                    .placeholder {
                        Image("placeholder_rectangle_32")
                    }
                    .frame(width: .iconSize32, height: .iconSize32)

                Text(value).themeBody()

                if let explorerUrl {
                    Button(
                        action: { open(url: explorerUrl) },
                        label: { Image("globe_20") }
                    )
                    .buttonStyle(SecondaryCircleButtonStyle(style: .default))
                }
            }
        }
    }

    private func open(url _: String) {
//        UrlManager(inApp: true).open(url: url, from: self)
    }
}

extension BottomSheetTitleView.Image.TintType {
    var color: Color {
        switch self {
        case .none: return .clear
        case .gray: return .themeGray
        case .warning: return .themeJacob
        case .alert: return .themeLucian
        }
    }
}

extension BottomSheetTitleView.Image {
    @ViewBuilder func view() -> some View {
        switch self {
        case let .local(name, tint):
            if let name {
                switch tint {
                case .none:
                    Image(name)
                        .frame(width: .iconSize24, height: .iconSize24)
                default:
                    Image(name).themeIcon(color: tint.color)
                        .frame(width: .iconSize24, height: .iconSize24)
                }
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
}

extension AlertView {
    struct InfoDescription: Identifiable {
        let title: String
        let description: String

        var id: String {
            title + description
        }
    }
}

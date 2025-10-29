import Kingfisher
import SwiftUI

struct BottomSheetView: View {
    private let icon: Icon?
    private let title: String
    private let colorStyle: ColorStyle?
    private let subtitle: String?
    private let items: [Item]

    @Binding private var isPresented: Bool
    @StateObject private var selectorViewModel: SelectorGroupsViewModel
    @StateObject private var buttonViewModel: ButtonGroupViewModel

    init(
        icon: Icon? = nil,
        title: String,
        colorStyle: ColorStyle? = nil,
        subtitle: String? = nil,
        items: [Item],
        isPresented: Binding<Bool>,
        selectorViewModel: SelectorGroupsViewModel,
        buttonViewModel: ButtonGroupViewModel
    ) {
        self.icon = icon
        self.title = title
        self.colorStyle = colorStyle
        self.subtitle = subtitle
        self.items = items
        _isPresented = isPresented
        _selectorViewModel = StateObject(wrappedValue: selectorViewModel)
        _buttonViewModel = StateObject(wrappedValue: buttonViewModel)
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: .margin2) {
                TitleView(
                    icon: icon,
                    title: title,
                    subtitle: subtitle
                )

                ContentView(
                    items: items,
                    selectorViewModel: selectorViewModel,
                    buttonViewModel: buttonViewModel
                )
            }
        }
    }
}

extension BottomSheetView {
    static func instance(
        icon: Icon? = nil,
        title: String,
        colorStyle: ColorStyle? = nil,
        subtitle: String? = nil,
        items: [Item] = [],
        isPresented: Binding<Bool>
    ) -> BottomSheetView {
        let selectorViewModel = SelectorGroupsViewModel()
        let buttonViewModel = ButtonGroupViewModel()

        // Проходим по items и регистрируем группы
        for item in items {
            switch item {
            case let .groupSelector(group):
                selectorViewModel.append(id: group.id, initialSelection: [])

            case let .buttonGroup(group):
                for button in group.buttons {
                    buttonViewModel.append(id: button.id, isDisabled: false)
                }

            default:
                break
            }
        }

        return BottomSheetView(
            icon: icon,
            title: title,
            colorStyle: colorStyle,
            subtitle: subtitle,
            items: items,
            isPresented: isPresented,
            selectorViewModel: selectorViewModel,
            buttonViewModel: buttonViewModel
        )
    }
}

extension BottomSheetView {
    struct ContentView: View {
        let items: [Item]
        @ObservedObject var selectorViewModel: SelectorGroupsViewModel
        @ObservedObject var buttonViewModel: ButtonGroupViewModel

        var body: some View {
            VStack(spacing: 0) {
                if !items.isEmpty {
                    ForEach(items.indices, id: \.self) { index in
                        itemView(item: items[index])
                    }
                }
            }
        }

        @ViewBuilder
        private func itemView(item: Item) -> some View {
            switch item {
            case let .text(text):
                ThemeText(text, style: .body, colorStyle: .secondary)
                    .multilineTextAlignment(.center)
                    .frame(alignment: .center)
                    .padding(.horizontal, .margin32)
                    .padding(.vertical, .margin16)

            case let .footer(text):
                ThemeText(text, style: .subhead)
                    .padding(.horizontal, .margin32)
                    .padding(.top, .margin12)
                    .padding(.bottom, .margin24)

            case let .group(items):
                ListForEach(items) { item in
                    Cell(
                        style: .secondary,
                        middle: {
                            ThemeText(item.title, style: .subhead)
                        },
                        right: {
                            ThemeText(item.value, style: .subheadSB)
                        }
                    )
                }
                .themeListStyle(.bordered)
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin8)

            case let .highlightedDescription(text, style, type):
                AlertCardView(.init(text: text, type: type, style: style))
                    .padding(.margin16)

            case let .groupSelector(group):
                SelectorGroupView(group: group, viewModel: selectorViewModel)
                    .padding(.horizontal, .margin16)
                    .padding(.vertical, .margin8)

            case let .buttonGroup(group):
                ButtonGroupView(group: group, viewModel: buttonViewModel)
                    .padding(.horizontal, .margin24)
                    .padding(.top, .margin24)
                    .padding(.bottom, .margin16)
            }
        }
    }
}

extension BottomSheetView {
    struct TitleView: View {
        private let icon: Icon?
        private let title: String
        private let colorStyle: ColorStyle?
        private let subtitle: String?

        init(icon: Icon? = nil, title: String, colorStyle: ColorStyle? = nil, subtitle: String? = nil) {
            self.icon = icon
            self.title = title
            self.colorStyle = colorStyle
            self.subtitle = subtitle
        }

        var body: some View {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.themeBlade)
                    .frame(width: 52, height: 4)
                    .cornerRadius(2)
                    .padding(.top, .margin8)
                    .padding(.bottom, .margin12)

                if let icon {
                    iconView(icon: icon)
                        .padding(.top, .margin16)
                        .padding(.bottom, .margin8)
                }

                ThemeText(title, style: .headline1, colorStyle: colorStyle)
                    .padding(.top, .margin16)
                    .padding(.bottom, .margin8)

                if let subtitle {
                    ThemeText(subtitle, style: .subhead)
                        .padding(.bottom, .margin16)
                }
            }
            .padding(.horizontal, .margin48)
        }

        @ViewBuilder
        private func iconView(icon: Icon) -> some View {
            switch icon {
            case let .local(name, style):
                Image(name)
                    .icon(size: .iconSize72, colorStyle: style ?? .secondary)
            case let .remote(url: url, placeholder: placeholder):
                KFImage.url(URL(string: url))
                    .resizable()
                    .placeholder {
                        if let placeholder {
                            Image(placeholder)
                        } else {
                            RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous)
                                .fill(Color.themeBlade)
                        }
                    }
                    .frame(width: .iconSize72, height: .iconSize72)
            }
        }
    }
}

extension BottomSheetView {
    enum Icon {
        case local(name: String, style: ColorStyle?)
        case remote(url: String, placeholder: String?)

        static let warning: Self = .local(name: "warning_filled", style: .yellow)
        static let error: Self = .local(name: "warning_filled", style: .red)
        static let info: Self = .local(name: "warning_filled", style: .secondary)
        static let book: Self = .local(name: "book", style: .secondary)
        static let trash: Self = .local(name: "trash_filled", style: .red)
    }

    enum Item {
        case text(text: CustomStringConvertible)
        case footer(text: CustomStringConvertible)
        case highlightedDescription(text: String, style: AlertCardView.Style, type: AlertCardView.CardType)
        case group(items: [GroupItem])
        case groupSelector(GroupSelector)
        case buttonGroup(ButtonGroupViewModel.ButtonGroup)

        static func error(text: String) -> Self {
            .highlightedDescription(text: text, style: .inline, type: .critical)
        }

        static func warning(text: String) -> Self {
            .highlightedDescription(text: text, style: .inline, type: .caution)
        }
    }

    struct GroupItem: Hashable, Equatable, Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }
}

struct InfoDescription: Identifiable {
    let title: String
    let description: String

    var id: String {
        title + description
    }
}

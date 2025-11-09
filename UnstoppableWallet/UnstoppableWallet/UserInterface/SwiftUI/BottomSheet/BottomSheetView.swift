import Kingfisher
import SwiftUI

enum BSModule {
    static func view(for item: Item) -> AnyView {
        switch item {
        case let .title(showGrabber, icon, title, isPresented): return AnyView(
                BSTitleView(showGrabber: showGrabber, icon: icon, title: title, isPresented: isPresented))
        case let .subtitle(text):
            return AnyView(
                ThemeText(text, style: .subhead)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .margin32)
                    .padding(.bottom, .margin16)
            )
        case let .text(text):
            return AnyView(
                ThemeText(text, style: .body, colorStyle: .secondary)
                    .multilineTextAlignment(.center)
                    .frame(alignment: .center)
                    .padding(.horizontal, .margin32)
                    .padding(.vertical, .margin16)
            )
        case let .footer(text):
            return AnyView(
                ThemeText(text, style: .subhead)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, .margin32)
                    .padding(.top, .margin12)
                    .padding(.bottom, .margin24)
            )

        case let .highlightedDescription(text, type, style):
            return AnyView(AlertCardView(.init(text: text, type: type, style: style)))

        case let .list(items):
            return AnyView(
                VStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        listView(item: items[index])
                    }
                }
                .padding(.vertical, .margin8)
                .clipShape(RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: .cornerRadius16, style: .continuous)
                        .stroke(Color.themeBlade, lineWidth: .heightOneDp)
                )
                .padding(.horizontal, .margin16)
                .padding(.vertical, .margin8)
            )
        case let .buttonGroup(group):
            return AnyView(ButtonGroupView(group: group))
        }
    }

    private static func listView(item: ListItem) -> some View {
        Cell(
            style: .secondary,
            middle: {
                MultiText(subtitle: item.title)
            },
            right: {
                RightMultiText(subtitle: item.value)
            }
        )
    }
}

extension BSModule {
    enum Item {
        case title(showGrabber: Bool, icon: BSTitleView.Icon?, title: CustomStringConvertible, isPresented: Binding<Bool>?)
        case subtitle(text: CustomStringConvertible)
        case text(text: CustomStringConvertible)
        case footer(text: CustomStringConvertible)
        case highlightedDescription(text: String, type: AlertCardView.CardType, style: AlertCardView.Style)
        case list(items: [ListItem])
        case buttonGroup(ButtonGroupViewModel.ButtonGroup)

        static func title(icon: BSTitleView.Icon? = nil, title: CustomStringConvertible) -> Self {
            .title(showGrabber: true, icon: icon, title: title, isPresented: nil)
        }

        static func error(text: String) -> Self {
            .highlightedDescription(text: text, type: .critical, style: .inline)
        }

        static func warning(text: String) -> Self {
            .highlightedDescription(text: text, type: .caution, style: .inline)
        }
    }

    struct ListItem {
        let title: CustomStringConvertible
        let value: CustomStringConvertible
    }
}

struct BottomSheetView: View {
    private let views: [AnyView]

    init(items: [BSModule.Item]) {
        views = items.map { BSModule.view(for: $0) }
    }

    init(views: [AnyView]) {
        self.views = views
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                ForEach(views.indices, id: \.self) { index in
                    views[index]
                }
            }
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

class BottomSheetWrapperView: UIHostingController<BottomSheetView> {
    init(items: [BSModule.Item]) {
        let view = BottomSheetView(items: items)
        super.init(rootView: view)
    }

    @available(*, unavailable)
    @MainActor dynamic required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

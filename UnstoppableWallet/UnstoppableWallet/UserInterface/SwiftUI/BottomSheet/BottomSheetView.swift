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
                    .padding(.horizontal, .margin32)
                    .padding(.top, .margin12)
                    .padding(.bottom, .margin24)
            )

        case let .highlightedDescription(text, type, style):
            return AnyView(AlertCardView(.init(text: text, type: type, style: style)))

        case let .buttonGroup(group):
            return AnyView(ButtonGroupView(group: group))
        }
    }
}

extension BSModule {
    enum Item {
        case title(showGrabber: Bool, icon: BSTitleView.Icon?, title: CustomStringConvertible, isPresented: Binding<Bool>?)
        case subtitle(text: CustomStringConvertible)
        case text(text: CustomStringConvertible)
        case footer(text: CustomStringConvertible)
        case highlightedDescription(text: String, type: AlertCardView.CardType, style: AlertCardView.Style)
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

    struct GroupItem: Hashable, Equatable, Identifiable {
        let id = UUID()
        let title: String
        let value: String
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

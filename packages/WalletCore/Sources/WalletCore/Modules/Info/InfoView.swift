import SwiftUI

struct InfoView: View {
    private let viewItems: [InfoModule.ViewItem]
    @Binding private var isPresented: Bool

    init(viewItems: [InfoModule.ViewItem], isPresented: Binding<Bool>) {
        self.viewItems = viewItems
        _isPresented = isPresented
    }

    var body: some View {
        ScrollableThemeView {
            LazyVStack(spacing: 0) {
                ForEach(viewItems.indexedElements) { item in
                    MarkdownBlockView(viewItem: item.element.markdownBlockViewItem)
                }
            }
            .padding(.bottom, .margin32)
        }
        .closeNavigation(isPresented: $isPresented)
    }
}

extension InfoModule.ViewItem {
    private typealias Converter = MarkdownAttributedStringConverter

    var markdownBlockViewItem: MarkdownBlockViewItem {
        switch self {
        case let .header1(text):
            return .header(attributedString: Converter.attributedString(string: text, font: .title2, color: .themeLeah), level: 1)
        case let .header3(text):
            return .header(attributedString: Converter.attributedString(string: text, font: .headline2, color: .themeJacob), level: 3)
        case let .text(text):
            return .text(attributedString: Converter.attributedString(string: text, font: .body, color: .themeBran))
        case let .listItem(text):
            return .listItem(
                attributedString: Converter.attributedString(string: text, font: .body, color: .themeBran),
                prefix: Converter.attributedString(string: "•", font: .body, color: .themeBran),
                tightTop: false,
                tightBottom: false
            )
        }
    }
}

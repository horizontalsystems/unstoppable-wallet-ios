import SwiftUI

struct ListSection<Content: View>: View {
    @Environment(\.themeListStyle) var themeListStyle

    private let selected: Bool
    private let header: String?
    private let footer: String?
    private let content: Content

    init(selected: Bool = false, header: String? = nil, footer: String? = nil, @ViewBuilder content: () -> Content) {
        self.selected = selected
        self.header = header
        self.footer = footer
        self.content = content()
    }

    var body: some View {
        _VariadicView.Tree(Layout(themeListStyle: themeListStyle, selected: selected, header: header, footer: footer)) {
            content
        }
    }

    struct Layout: _VariadicView_MultiViewRoot {
        let themeListStyle: ThemeListStyle
        let selected: Bool
        let header: String?
        let footer: String?

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            if children.isEmpty {
                EmptyView()
            } else {
                let last = children.last?.id

                VStack(spacing: 0) {
                    if let header {
                        ListSectionHeader(text: header)
                    }

                    VStack(spacing: 0) {
                        switch themeListStyle {
                        case .lawrence, .bordered, .transparentInline, .blur, .steel10WithCorners:
                            ForEach(children) { child in
                                child

                                if child.id != last {
                                    HorizontalDivider()
                                }
                            }
                        case .transparent, .borderedLawrence:
                            HorizontalDivider()

                            ForEach(children) { child in
                                child
                                HorizontalDivider()
                            }
                        }
                    }
                    .modifier(ThemeListStyleModifier(themeListStyle: themeListStyle, selected: selected))

                    if let footer {
                        ListSectionFooter(text: footer)
                    }
                }
            }
        }
    }
}

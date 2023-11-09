import SwiftUI

struct ListSection<Content: View>: View {
    @Environment(\.themeListStyle) var listStyle

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(Layout()) {
                content
            }
            .modifier(ThemeListStyleModifier(themeListStyle: listStyle))
        }
    }

    struct Layout: _VariadicView_UnaryViewRoot {
        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            let last = children.last?.id

            VStack(spacing: 0) {
                ForEach(children) { child in
                    child

                    if child.id != last {
                        HorizontalDivider()
                    }
                }
            }
        }
    }
}

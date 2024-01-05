import SwiftUI

struct ListSection<Content: View>: View {
    @Environment(\.themeListStyle) var themeListStyle

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(Layout(themeListStyle: themeListStyle)) {
                content
            }
            .modifier(ThemeListStyleModifier(themeListStyle: themeListStyle))
        }
    }

    struct Layout: _VariadicView_UnaryViewRoot {
        let themeListStyle: ThemeListStyle

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            let last = children.last?.id

            VStack(spacing: 0) {
                switch themeListStyle {
                case .lawrence, .bordered, .transparentInline:
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
        }
    }
}

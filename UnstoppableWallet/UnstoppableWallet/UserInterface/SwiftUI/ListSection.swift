import SwiftUI

struct ListSection<Content: View>: View {
    @Environment(\.themeListStyle) var themeListStyle

    private let selected: Bool
    private let content: Content

    init(selected: Bool = false, @ViewBuilder content: () -> Content) {
        self.selected = selected
        self.content = content()
    }

    var body: some View {
        _VariadicView.Tree(Layout(themeListStyle: themeListStyle, selected: selected)) {
            content
        }
    }

    struct Layout: _VariadicView_MultiViewRoot {
        let themeListStyle: ThemeListStyle
        let selected: Bool

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            if children.isEmpty {
                EmptyView()
            } else {
                let last = children.last?.id

                VStack(spacing: 0) {
                    switch themeListStyle {
                    case .lawrence, .bordered, .transparentInline, .blur, .steel10WithBottomCorners:
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
            }
        }
    }
}

import SwiftUI

struct ListSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        _VariadicView.Tree(Layout()) {
            content
        }
    }

    struct Layout: _VariadicView_MultiViewRoot {
        @ViewBuilder func body(children: _VariadicView.Children) -> some View {
            if children.isEmpty {
                EmptyView()
            } else {
                let last = children.last?.id

                VStack(spacing: 0) {
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
    }
}

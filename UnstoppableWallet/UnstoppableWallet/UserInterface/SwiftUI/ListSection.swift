import SwiftUI

struct ListSection<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(Layout()) {
                        content
                    }
                    .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
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

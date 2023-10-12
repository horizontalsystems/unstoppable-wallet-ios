import SwiftUI

struct ListSection<Content: View>: View {
    @Environment(\.listStyle) var listStyle

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(Layout()) {
                content
            }
            .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(listStyle.backgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: .cornerRadius12).stroke(listStyle.borderColor, lineWidth: .heightOneDp))
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

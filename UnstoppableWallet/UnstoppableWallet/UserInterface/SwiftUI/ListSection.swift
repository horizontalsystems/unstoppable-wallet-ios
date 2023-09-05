import SwiftUI

struct ListSection<Content: View>: View {
    var content: Content
    var footerText: String?

    init(footerText: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.footerText = footerText
    }

    var body: some View {
        VStack(spacing: 0) {
            _VariadicView.Tree(Layout()) {
                        content
                    }
                    .background(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous).fill(Color.themeLawrence))
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadius12, style: .continuous))

            if let footerText {
                Text(footerText)
                        .themeSubhead2()
                        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: 0, trailing: .margin16))
            }
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

import SwiftUI

struct ListRow<Content: View>: View {
    private let spacing: CGFloat
    private let minHeight: CGFloat
    @ViewBuilder private let content: Content

    init(spacing: CGFloat = .margin16, minHeight: CGFloat = .heightCell48, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16))
        .frame(minHeight: minHeight)
    }
}

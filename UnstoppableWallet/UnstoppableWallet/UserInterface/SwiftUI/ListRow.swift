import SwiftUI

struct ListRow<Content: View>: View {
    private let padding: EdgeInsets
    private let spacing: CGFloat
    private let minHeight: CGFloat
    @ViewBuilder private let content: Content

    init(padding: EdgeInsets = EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), spacing: CGFloat = .margin16, minHeight: CGFloat = .heightCell48, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.spacing = spacing
        self.minHeight = minHeight
        self.content = content()
    }

    var body: some View {
        HStack(spacing: spacing) {
            content
        }
        .padding(padding)
        .frame(minHeight: minHeight)
    }
}

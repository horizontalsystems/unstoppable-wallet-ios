import SwiftUI

struct ClickableRow<Content: View>: View {
    private let padding: EdgeInsets
    private let spacing: CGFloat
    private let action: () -> Void
    @ViewBuilder private let content: Content

    init(padding: EdgeInsets = EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), spacing: CGFloat = .margin16, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.spacing = spacing
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action, label: {
            ListRow(padding: padding, spacing: spacing) {
                content
            }
        })
        .buttonStyle(RowButtonStyle())
        .contentShape(Rectangle())
    }
}

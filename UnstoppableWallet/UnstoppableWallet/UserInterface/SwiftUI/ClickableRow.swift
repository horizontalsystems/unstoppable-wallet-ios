import SwiftUI

struct ClickableRow<Content: View>: View {
    private let spacing: CGFloat
    private let action: () -> Void
    @ViewBuilder private let content: Content

    init(spacing: CGFloat = .margin16, action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.action = action
        self.content = content()
    }

    var body: some View {
        Button(action: action, label: {
            ListRow(spacing: spacing) {
                content
            }
        })
        .buttonStyle(RowButtonStyle())
        .contentShape(Rectangle())
    }
}

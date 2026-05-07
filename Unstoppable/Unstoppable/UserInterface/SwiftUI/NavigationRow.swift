import SwiftUI

struct NavigationRow<Content: View, Destination: View>: View {
    private let padding: EdgeInsets
    private let spacing: CGFloat
    private let minHeight: CGFloat

    @ViewBuilder let destination: Destination
    @ViewBuilder let content: Content

    init(padding: EdgeInsets = EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), spacing: CGFloat = .margin16, minHeight: CGFloat = .heightCell48, @ViewBuilder destination: () -> Destination, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.spacing = spacing
        self.minHeight = minHeight
        self.destination = destination()
        self.content = content()
    }

    var body: some View {
        let row = ListRow(padding: padding, spacing: spacing, minHeight: minHeight) {
            content
        }

        NavigationLink(destination: destination) { row }
            .buttonStyle(RowButtonStyle())
    }
}

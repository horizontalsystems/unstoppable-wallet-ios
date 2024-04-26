import SwiftUI

struct NavigationRow<Content: View, Destination: View>: View {
    private let padding: EdgeInsets
    private let spacing: CGFloat
    private let minHeight: CGFloat

    @ViewBuilder let destination: Destination
    var isActive: Binding<Bool>?
    @ViewBuilder let content: Content

    init(padding: EdgeInsets = EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin12, trailing: .margin16), spacing: CGFloat = .margin16, minHeight: CGFloat = .heightCell48, @ViewBuilder destination: () -> Destination, isActive: Binding<Bool>? = nil, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.spacing = spacing
        self.minHeight = minHeight
        self.destination = destination()
        self.isActive = isActive
        self.content = content()
    }

    var body: some View {
        let row = ListRow(padding: padding, spacing: spacing, minHeight: minHeight) {
            content
        }
        if let isActive {
            NavigationLink(destination: destination, isActive: isActive) { row }
                .buttonStyle(RowButtonStyle())
        } else {
            NavigationLink(destination: destination) { row }
                .buttonStyle(RowButtonStyle())
        }
    }
}

import SwiftUI

struct NavigationRow<Content: View, Destination: View>: View {
    @ViewBuilder let destination: Destination
    var isActive: Binding<Bool>?
    @ViewBuilder let content: Content

    var body: some View {
        let row = ListRow {
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

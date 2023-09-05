import SwiftUI

struct NavigationRow<Content: View, Destination: View>: View {
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let content: Content

    var body: some View {
        NavigationLink(destination: destination) {
            ListRow {
                content
            }
        }
                .buttonStyle(RowButton())
    }
}

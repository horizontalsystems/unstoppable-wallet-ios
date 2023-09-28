import SwiftUI

struct ClickableRow<Content: View>: View {
    let action: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        Button(action: action, label: {
            ListRow {
                content
            }
        })
        .buttonStyle(RowButtonStyle())
        .contentShape(Rectangle())
    }
}

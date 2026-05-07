import SwiftUI

struct SyncErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        PlaceholderViewNew(icon: "sync_error_48", subtitle: "sync_error".localized) {
            Button(action: {
                onRetry()
            }) {
                Text("button.retry".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .yellow))
        }
    }
}

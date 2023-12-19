import SwiftUI

struct SyncErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        PlaceholderViewNew(image: Image("sync_error_48"), text: "sync_error".localized) {
            Button(action: {
                onRetry()
            }) {
                Text("button.retry".localized)
            }
            .buttonStyle(PrimaryButtonStyle(style: .yellow))
        }
    }
}

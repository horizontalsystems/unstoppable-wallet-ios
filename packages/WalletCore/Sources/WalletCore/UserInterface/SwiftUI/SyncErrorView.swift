import SwiftUI

struct SyncErrorView: View {
    let onRetry: () -> Void

    var body: some View {
        PlaceholderViewNew(icon: "sync_error_48", subtitle: "sync_error".localized) {
            ThemeButton(text: "button.retry".localized) {
                onRetry()
            }
        }
    }
}

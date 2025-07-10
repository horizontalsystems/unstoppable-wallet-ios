import SwiftUI

struct AccountWarningView: View {
    @ObservedObject var viewModel: AccountWarningViewModel

    var body: some View {
        if let item = viewModel.item {
            HighlightedTextView(caution: item.caution, onClose: item.canIgnore ? {
                viewModel.onIgnore()
            } : nil)
                .onTapGesture {
                    if let url = item.url {
                        Coordinator.shared.present { _ in
                            MarkdownView(url: url, navigation: true).ignoresSafeArea()
                        }
                    }
                }
        }
    }
}

import MarketKit
import SwiftUI

struct RegularMultiSwapView: View {
    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var viewModel: MultiSwapViewModel
    @StateObject private var splitViewModel: SplitSwapViewModel
    @State private var sendPresented = false
    @State private var splitRecipientsPresented = false
    @State private var splitSendPresented = false

    init(token: Token? = nil, tokenOut: Token? = nil) {
        _viewModel = StateObject(wrappedValue: MultiSwapViewModel(token: token, tokenOut: tokenOut))
        // same entry tokens as the Standard tab, independent afterwards
        _splitViewModel = StateObject(wrappedValue: SplitSwapViewModel(token: token, tokenOut: tokenOut))
    }

    var body: some View {
        ThemeNavigationStack {
            MultiSwapView(
                viewModel: viewModel,
                splitViewModel: splitViewModel,
                sendPresented: $sendPresented,
                splitRecipientsPresented: $splitRecipientsPresented,
                autoFocus: true
            )
            .navigationDestination(isPresented: $sendPresented) {
                MultiSwapSendDestinationView(viewModel: viewModel) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationDestination(isPresented: $splitRecipientsPresented) {
                SplitSwapRecipientsView(viewModel: splitViewModel) {
                    splitSendPresented = true
                }
                .navigationDestination(isPresented: $splitSendPresented) {
                    SplitSwapSendDestinationView(viewModel: splitViewModel) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("swap.title".localized)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Coordinator.shared.present { isPresented in
                            SwapHistoryView(isPresented: isPresented)
                        }
                    }) {
                        Image("clock")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }
}

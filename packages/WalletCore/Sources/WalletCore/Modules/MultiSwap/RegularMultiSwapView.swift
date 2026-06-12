import MarketKit
import SwiftUI

struct RegularMultiSwapView: View {
    @Environment(\.presentationMode) private var presentationMode

    @StateObject private var viewModel: MultiSwapViewModel
    @State private var sendPresented = false

    init(token: Token? = nil) {
        _viewModel = StateObject(wrappedValue: MultiSwapViewModel(token: token))
    }

    var body: some View {
        ThemeNavigationStack {
            MultiSwapView(viewModel: viewModel, sendPresented: $sendPresented)
                .navigationDestination(isPresented: $sendPresented) {
                    MultiSwapSendDestinationView(viewModel: viewModel) {
                        presentationMode.wrappedValue.dismiss()
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

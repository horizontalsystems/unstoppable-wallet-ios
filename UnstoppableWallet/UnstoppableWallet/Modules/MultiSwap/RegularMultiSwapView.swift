import MarketKit
import SwiftUI

struct RegularMultiSwapView: View {
    @Environment(\.presentationMode) private var presentationMode

    var token: Token? = nil

    var body: some View {
        ThemeNavigationStack {
            MultiSwapView(token: token) {
                presentationMode.wrappedValue.dismiss()
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

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
                ToolbarItem {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

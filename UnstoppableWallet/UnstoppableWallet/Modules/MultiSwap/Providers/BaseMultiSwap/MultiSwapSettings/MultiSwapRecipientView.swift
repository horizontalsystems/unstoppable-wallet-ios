import Foundation
import MarketKit
import SwiftUI

struct MultiSwapRecipientView: View {
    @Environment(\.presentationMode) private var presentationMode

    private let address: String?
    private let token: Token
    private let onChange: (String?) -> Void

    init(address: String?, token: Token, onChange: @escaping (String?) -> Void) {
        self.address = address
        self.token = token
        self.onChange = onChange
    }

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                AddressView(token: token, buttonTitle: "button.apply".localized, destination: .swap, address: address) { address in
                    onChange(address?.address)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .navigationTitle("address.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

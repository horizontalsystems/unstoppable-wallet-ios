import Foundation
import MarketKit
import SwiftUI

public struct MultiSwapRecipientView: View {
    @Environment(\.presentationMode) private var presentationMode

    private let address: String?
    private let token: Token
    // a mandatory external recipient (tokenOut the account can't hold) can be changed
    // but never removed — there is no own-wallet address to fall back to
    private let allowRemoval: Bool
    private let parserFilter: AddressParserFactory.ParserFilter?
    private let onChange: (String?) -> Void

    init(address: String?, token: Token, allowRemoval: Bool = true, parserFilter: AddressParserFactory.ParserFilter? = nil, onChange: @escaping (String?) -> Void) {
        self.address = address
        self.token = token
        self.allowRemoval = allowRemoval
        self.parserFilter = parserFilter
        self.onChange = onChange
    }

    public var body: some View {
        ThemeNavigationStack {
            ThemeView {
                AddressView(token: token, buttonTitle: "button.apply".localized, destination: .swap, address: address, mustChangeAddress: true, allowRemoval: allowRemoval) { address in
                    onChange(address?.address)
                    presentationMode.wrappedValue.dismiss()
                }
                .environment(\.addressParserFilter, parserFilter)
            }
            .navigationTitle("address.title".localized)
            .toolbar {
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

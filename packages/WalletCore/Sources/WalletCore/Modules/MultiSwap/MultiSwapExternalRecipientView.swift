import MarketKit
import SwiftUI

/// Mandatory recipient step for swaps whose tokenOut the active account can't hold
/// (e.g. a Monero-only account swapping XMR to TRX): the swapped funds can only be
/// delivered to an external wallet, so the user enters it before the confirmation.
struct MultiSwapExternalRecipientView: View {
    let token: Token
    let initialAddress: String?
    @Binding var isPresented: Bool
    let onProceed: (String) -> Void

    var body: some View {
        ThemeNavigationStack {
            ThemeView {
                VStack(spacing: 0) {
                    ThemeText("swap.external_recipient.description".localized, style: .subhead)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AddressView(
                        token: token,
                        buttonTitle: "button.next".localized,
                        destination: .swap,
                        address: initialAddress,
                        allowRemoval: false
                    ) { resolvedAddress in
                        guard let resolvedAddress else {
                            return
                        }

                        onProceed(resolvedAddress.address)
                        isPresented = false
                    }
                    // The provider is not chosen yet at this step, and only Maya delivers ZEC
                    // to shielded/unified receivers — every provider accepts transparent, so
                    // an external ZEC recipient is restricted to transparent addresses.
                    .environment(\.addressParserFilter, token.blockchainType == .zcash ? .zCashTransparentOnly : nil)
                }
            }
            .navigationTitle("swap.recipient".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }
}

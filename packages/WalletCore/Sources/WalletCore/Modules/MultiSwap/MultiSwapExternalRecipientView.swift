import MarketKit
import SwiftUI

/// Mandatory recipient step for swaps whose tokenOut the active account can't hold
/// (e.g. a Monero-only account swapping XMR to TRX): the swapped funds can only be
/// delivered to an external wallet, so the user enters it before the confirmation.
struct MultiSwapExternalRecipientView: View {
    let token: Token
    let initialAddress: String?
    /// Whether any quoted route takes a unified ZEC address (`addressRules.destination.unified`);
    /// otherwise an external ZEC recipient is restricted to transparent addresses, which every route takes.
    let allowsUnifiedZcash: Bool
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
                    .environment(\.addressParserFilter, parserFilter)
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

    private var parserFilter: AddressParserFactory.ParserFilter? {
        guard token.blockchainType == .zcash, !allowsUnifiedZcash else {
            return nil
        }

        return .zCashTransparentOnly
    }
}

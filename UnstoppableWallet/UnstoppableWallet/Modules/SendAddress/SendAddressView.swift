
import SwiftUI

struct SendAddressView: View {
    private let wallet: Wallet
    private let address: String?
    private let fromAddress: String?
    private let amount: Decimal?
    private let onDismiss: (() -> Void)?

    @Environment(\.presentationMode) private var presentationMode

    @State private var resolvedAddress: ResolvedAddress?

    init(wallet: Wallet, address: String? = nil, amount: Decimal? = nil, onDismiss: (() -> Void)? = nil) {
        self.wallet = wallet
        self.address = address
        self.amount = amount
        self.onDismiss = onDismiss

        fromAddress = Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address
    }

    var body: some View {
        ThemeView {
            AddressView(token: wallet.token, buttonTitle: "send.next_button".localized, destination: .send(fromAddress: fromAddress), address: address) { resolvedAddress in
                self.resolvedAddress = resolvedAddress
            }

            NavigationLink(
                isActive: Binding(
                    get: {
                        resolvedAddress != nil
                    }, set: { active in
                        if !active {
                            resolvedAddress = nil
                        }
                    }
                ),
                destination: {
                    if let resolvedAddress, let handler = SendHandlerFactory.preSendHandler(wallet: wallet) {
                        PreSendView(wallet: wallet, handler: handler, resolvedAddress: resolvedAddress, amount: amount) {
                            if let onDismiss {
                                onDismiss()
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }
                        .toolbarRole(.editor)
                    }
                }
            ) {
                EmptyView()
            }
        }
        .navigationTitle("address.title".localized)
        .navigationBarTitleDisplayMode(.inline)
        // .toolbar {
        //     ToolbarItem(placement: .navigationBarTrailing) {
        //         Button("button.cancel".localized) {
        //             presentationMode.wrappedValue.dismiss()
        //         }
        //     }
        // }
    }
}

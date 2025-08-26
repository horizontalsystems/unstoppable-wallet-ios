
import SwiftUI

struct SendAddressView: View {
    private let wallet: Wallet
    private let address: String?
    private let fromAddress: String?
    private let amount: Decimal?
    @Binding var isPresented: Bool
    private let onDismiss: (() -> Void)?

    @State private var resolvedAddress: ResolvedAddress?

    init(wallet: Wallet, address: String? = nil, amount: Decimal? = nil, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self.wallet = wallet
        self.address = address
        self.amount = amount
        _isPresented = isPresented
        self.onDismiss = onDismiss

        fromAddress = Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address
    }

    var body: some View {
        ThemeView {
            AddressView(token: wallet.token, buttonTitle: "send.next_button".localized, destination: .send(fromAddress: fromAddress), address: address) { resolvedAddress in
                self.resolvedAddress = resolvedAddress
            }
        }
        .navigationTitle("address.title".localized)
        .navigationDestination(
            isPresented: Binding(
                get: {
                    resolvedAddress != nil
                }, set: { active in
                    if !active {
                        resolvedAddress = nil
                    }
                }
            )
        ) {
            if let resolvedAddress, let handler = SendHandlerFactory.preSendHandler(wallet: wallet) {
                PreSendView(wallet: wallet, handler: handler, resolvedAddress: resolvedAddress, amount: amount) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        isPresented = false
                    }
                }
                .toolbarRole(.editor)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("button.cancel".localized) {
                    isPresented = false
                }
            }
        }
    }
}

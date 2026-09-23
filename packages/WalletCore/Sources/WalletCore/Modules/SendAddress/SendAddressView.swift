import SwiftUI

struct SendAddressView: View {
    private let wallet: Wallet
    private let address: String?
    private let buttonTitle: String
    private let fromAddress: String?
    private let onSelect: (ResolvedAddress) -> Void

    init(wallet: Wallet, address: String? = nil, buttonTitle: String = "button.apply".localized, onSelect: @escaping (ResolvedAddress) -> Void) {
        self.wallet = wallet
        self.address = address
        self.buttonTitle = buttonTitle
        self.onSelect = onSelect

        fromAddress = Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address
    }

    var body: some View {
        ThemeView {
            AddressView(token: wallet.token, buttonTitle: buttonTitle, destination: .send(fromAddress: fromAddress), address: address, allowRemoval: false) { resolvedAddress in
                if let resolvedAddress {
                    onSelect(resolvedAddress)
                }
            }
        }
        .navigationTitle("address.title".localized)
    }
}

struct SendAddressViewWrapper: View {
    let wallet: Wallet
    let address: String?
    @Binding var isPresented: Bool
    let onSelect: (ResolvedAddress) -> Void

    var body: some View {
        ThemeNavigationStack {
            SendAddressView(wallet: wallet, address: address) { resolvedAddress in
                onSelect(resolvedAddress)
                isPresented = false
            }
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

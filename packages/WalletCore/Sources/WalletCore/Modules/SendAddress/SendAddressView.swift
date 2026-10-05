import MarketKit
import SwiftUI

struct SendAddressView: View {
    private let token: Token
    private let address: String?
    private let buttonTitle: String
    private let fromAddress: String?
    private let onSelect: (ResolvedAddress) -> Void

    init(token: Token, fromAddress: String?, address: String? = nil, buttonTitle: String = "button.apply".localized, onSelect: @escaping (ResolvedAddress) -> Void) {
        self.token = token
        self.fromAddress = fromAddress
        self.address = address
        self.buttonTitle = buttonTitle
        self.onSelect = onSelect
    }

    init(wallet: Wallet, address: String? = nil, buttonTitle: String = "button.apply".localized, onSelect: @escaping (ResolvedAddress) -> Void) {
        self.init(
            token: wallet.token,
            fromAddress: Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address,
            address: address,
            buttonTitle: buttonTitle,
            onSelect: onSelect
        )
    }

    var body: some View {
        ThemeView {
            AddressView(token: token, buttonTitle: buttonTitle, destination: .send(fromAddress: fromAddress), address: address, allowRemoval: false) { resolvedAddress in
                if let resolvedAddress {
                    onSelect(resolvedAddress)
                }
            }
        }
        .navigationTitle("address.title".localized)
    }
}

struct SendAddressViewWrapper: View {
    let token: Token
    let fromAddress: String?
    let address: String?
    @Binding var isPresented: Bool
    let onSelect: (ResolvedAddress) -> Void

    init(token: Token, fromAddress: String?, address: String?, isPresented: Binding<Bool>, onSelect: @escaping (ResolvedAddress) -> Void) {
        self.token = token
        self.fromAddress = fromAddress
        self.address = address
        _isPresented = isPresented
        self.onSelect = onSelect
    }

    init(wallet: Wallet, address: String?, isPresented: Binding<Bool>, onSelect: @escaping (ResolvedAddress) -> Void) {
        self.init(
            token: wallet.token,
            fromAddress: Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address,
            address: address,
            isPresented: isPresented,
            onSelect: onSelect
        )
    }

    var body: some View {
        ThemeNavigationStack {
            SendAddressView(token: token, fromAddress: fromAddress, address: address) { resolvedAddress in
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


import SwiftUI

struct SendAddressView: View {
    private let wallet: Wallet
    private let address: String?
    private let fromAddress: String?
    private let amount: Decimal?
    private let memo: String?

    @Binding var path: NavigationPath
    @Binding var isPresented: Bool
    private let onDismiss: (() -> Void)?

    init(wallet: Wallet, address: String? = nil, amount: Decimal? = nil, memo: String? = nil, path: Binding<NavigationPath>, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self.wallet = wallet
        self.address = address
        self.amount = amount
        self.memo = memo
        _path = path
        _isPresented = isPresented
        self.onDismiss = onDismiss

        fromAddress = Core.shared.adapterManager.depositAdapter(for: wallet)?.receiveAddress.address
    }

    var body: some View {
        ThemeView {
            AddressView(token: wallet.token, buttonTitle: "send.next_button".localized, destination: .send(fromAddress: fromAddress), address: address) { resolvedAddress in
                path.append(resolvedAddress)
            }
        }
        .navigationTitle("address.title".localized)
        .navigationDestination(for: ResolvedAddress.self) { resolvedAddress in
            if let handler = SendHandlerFactory.preSendHandler(wallet: wallet, address: resolvedAddress) {
                PreSendView(wallet: wallet, handler: handler, resolvedAddress: resolvedAddress, amount: amount, memo: memo, path: $path) {
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

struct SendAddressViewWrapper: View {
    let wallet: Wallet
    @Binding var isPresented: Bool
    
    @State private var path = NavigationPath()

    var body: some View {
        ThemeNavigationStack(path: $path) {
            SendAddressView(wallet: wallet, path: $path, isPresented: $isPresented)
        }
    }
}

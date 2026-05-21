import MarketKit
import SwiftUI

// OCP wallet picker: opens RegularSendView directly (address/amount/memo already resolved).
struct CryptoPaySendTokenListView: View {
    @StateObject private var viewModel: SendTokenListViewModel

    @State private var searchText = ""
    @State private var blockchain: Blockchain?

    @Binding var isPresented: Bool
    private let prepare: (Wallet) async throws -> SendData

    init(options: SendTokenListViewModel.SendOptions, prepare: @escaping (Wallet) async throws -> SendData, isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SendTokenListViewModel(options: options))
        self.prepare = prepare
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            WalletPickerView(
                viewModel: viewModel,
                searchText: $searchText,
                blockchain: $blockchain,
                onSelect: { wallet in
                    select(wallet: wallet)
                },
                onFailed: { wallet, state in
                    Coordinator.shared.presentBalanceError(wallet: wallet, state: state)
                }
            )
            .navigationTitle("send.send".localized)
            .searchBar(text: $searchText, prompt: "placeholder.search".localized)
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

    private func select(wallet: Wallet) {
        stat(page: .sendTokenList, event: .openSend(token: wallet.token))

        Task { @MainActor in
            HudHelper.instance.show(banner: .preparing)
            do {
                let sendData = try await prepare(wallet)
                HudHelper.instance.hide()
                isPresented = false
                Coordinator.shared.present { presented in
                    RegularSendViewWrapper(sendData: sendData, address: nil, isPresented: presented, onSuccess: {})
                }
            } catch is CancellationError {
                HudHelper.instance.hide()
            } catch {
                HudHelper.instance.hide()
                HudHelper.instance.show(banner: .error(string: error.smartDescription))
            }
        }
    }
}

import MarketKit
import SwiftUI

struct SendTokenListView: View {
    @StateObject private var viewModel: SendTokenListViewModel

    @State private var path = NavigationPath()
    @State private var searchText = ""
    @State private var blockchainFilter: SendTokenListViewModel.BlockchainFilter? = .all

    @Binding var isPresented: Bool

    private let onPrepare: ((Wallet) async throws -> SendTokenListViewModel.SendOptions)?

    init(options: SendTokenListViewModel.SendOptions = .init(), isPresented: Binding<Bool>, onPrepare: ((Wallet) async throws -> SendTokenListViewModel.SendOptions)? = nil) {
        _viewModel = .init(wrappedValue: SendTokenListViewModel(options: options))
        _isPresented = isPresented
        self.onPrepare = onPrepare
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
                WalletPickerView(
                    viewModel: viewModel,
                    searchText: $searchText,
                    blockchainFilter: $blockchainFilter,
                    onSelect: { wallet in
                        select(wallet: wallet)
                    },
                    onFailed: { wallet, state in
                        Coordinator.shared.presentBalanceError(wallet: wallet, state: state)
                    }
                )
                .navigationTitle("send.send".localized)
                .searchBar(text: $searchText, prompt: "placeholder.search".localized, isActive: !viewModel.noTokens)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case let .send(wallet, options):
                        SendAddressView(
                            wallet: wallet,
                            address: options.address,
                            amount: options.amount?.humanReadable(decimals: wallet.token.decimals),
                            memo: options.memo,
                            path: $path,
                            isPresented: $isPresented
                        )
                    }
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

    private func select(wallet: Wallet) {
        stat(page: .sendTokenList, event: .openSend(token: wallet.token))

        guard let onPrepare else {
            path.append(Route.send(wallet, viewModel.options))
            return
        }

        Task { @MainActor in
            guard let prepared = try? await onPrepare(wallet) else { return }
            path.append(Route.send(wallet, prepared))
        }
    }
}

extension SendTokenListView {
    enum Route: Hashable {
        case send(Wallet, SendTokenListViewModel.SendOptions)
    }
}

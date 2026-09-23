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
                    case let .address(wallet, options):
                        SendAddressView(wallet: wallet, address: options.address, buttonTitle: "send.next_button".localized) { resolvedAddress in
                            path.append(Route.preSend(wallet, options, resolvedAddress))
                        }
                        .toolbarRole(.editor)
                    case let .preSend(wallet, options, resolvedAddress):
                        PreSendView(
                            wallet: wallet,
                            predefinedAddress: resolvedAddress,
                            amount: options.amount?.humanReadable(decimals: wallet.token.decimals),
                            memo: options.memo,
                            path: $path,
                            isPresented: $isPresented
                        )
                        .toolbarRole(.editor)
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
            path.append(route(wallet: wallet, options: viewModel.options))
            return
        }

        Task { @MainActor in
            guard let prepared = try? await onPrepare(wallet) else { return }
            path.append(route(wallet: wallet, options: prepared))
        }
    }

    private func route(wallet: Wallet, options: SendTokenListViewModel.SendOptions) -> Route {
        if options.address != nil {
            return .address(wallet, options)
        } else {
            return .preSend(wallet, options, nil)
        }
    }
}

extension SendTokenListView {
    enum Route: Hashable {
        case address(Wallet, SendTokenListViewModel.SendOptions)
        case preSend(Wallet, SendTokenListViewModel.SendOptions, ResolvedAddress?)
    }
}

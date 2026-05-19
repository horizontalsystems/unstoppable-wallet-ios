import MarketKit
import SwiftUI

struct SendTokenListView: View {
    @StateObject private var viewModel: SendTokenListViewModel

    @State private var path = NavigationPath()
    @State private var searchText = ""
    @State private var blockchain: Blockchain?

    @Binding var isPresented: Bool

    private let onPrepare: ((Wallet) async throws -> SendTokenListViewModel.SendOptions)?

    @FocusState var searchFocused: Bool

    init(options: SendTokenListViewModel.SendOptions = .init(), isPresented: Binding<Bool>, onPrepare: ((Wallet) async throws -> SendTokenListViewModel.SendOptions)? = nil) {
        _viewModel = .init(wrappedValue: SendTokenListViewModel(options: options))
        _isPresented = isPresented
        self.onPrepare = onPrepare
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
                VStack(spacing: 0) {
                    ScrollableTabHeaderView(
                        tabs: ["filter.all".localized] + blockchains.map(\.name),
                        currentTabIndex: Binding(
                            get: {
                                if let blockchain, let index = blockchains.firstIndex(of: blockchain) {
                                    return index + 1
                                } else {
                                    return 0
                                }
                            },
                            set: { index in
                                if index == 0 {
                                    blockchain = nil
                                } else {
                                    blockchain = blockchains[index - 1]
                                }
                            }
                        )
                    )

                    let items = filteredItems
                    if items.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "alert.not_founded".localized)
                    } else {
                        ThemeList(items) { item in
                            WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, amountRounding: viewModel.amountRounding, subtitleMode: .coinName, isReachable: viewModel.isReachable) {
                                select(wallet: item.wallet)
                            } failedAction: {
                                Coordinator.shared.presentBalanceError(wallet: item.wallet, state: item.state)
                            }
                        }
                    }
                }
            }
            .navigationTitle("send.send".localized)
            .searchBar(text: $searchText, prompt: "placeholder.search".localized)
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

    var filteredItems: [WalletListViewModel.Item] {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        let items: [WalletListViewModel.Item]

        if text.isEmpty {
            items = viewModel.itemsWithOptions
        } else {
            items = viewModel.itemsWithOptions.filter { item in
                item.wallet.token.coin.name.localizedCaseInsensitiveContains(text) || item.wallet.token.coin.code.localizedCaseInsensitiveContains(text)
            }
        }

        if let blockchain {
            return items.filter { $0.wallet.token.blockchainType == blockchain.type }
        } else {
            return items
        }
    }

    var blockchains: [Blockchain] {
        Array(Set(viewModel.itemsWithOptions.map(\.wallet.token.blockchain))).sorted { $0.type.order < $1.type.order }
    }
}

extension SendTokenListView {
    enum Route: Hashable {
        case send(Wallet, SendTokenListViewModel.SendOptions)
    }
}

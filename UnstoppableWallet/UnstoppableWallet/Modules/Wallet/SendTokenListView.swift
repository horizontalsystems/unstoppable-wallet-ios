import MarketKit
import SwiftUI

struct SendTokenListView: View {
    @StateObject private var viewModel: SendTokenListViewModel

    @State private var path = NavigationPath()
    @State private var searchText = ""
    @State private var blockchain: Blockchain?

    @Binding var isPresented: Bool

    @FocusState var searchFocused: Bool

    init(options: SendTokenListViewModel.SendOptions = .init(), isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SendTokenListViewModel(options: options))
        _isPresented = isPresented
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

                    ThemeList(items) { item in
                        WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, amountRounding: viewModel.amountRounding, subtitleMode: .coinName) {
                            path.append(item.wallet)
                            stat(page: .sendTokenList, event: .openSend(token: item.wallet.token))
                        } failedAction: {
                            Coordinator.shared.presentBalanceError(wallet: item.wallet, state: item.state)
                        }
                    }
                    .safeAreaInset(edge: .bottom) {
                        BottomSearchBar(text: $searchText, prompt: "placeholder.search".localized, focused: $searchFocused)
                    }
                }
            }
            .navigationDestination(for: Wallet.self) { wallet in
                SendAddressView(wallet: wallet, address: viewModel.options.address, amount: viewModel.options.amount, memo: viewModel.options.memo, isPresented: $isPresented)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("send.send".localized)
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

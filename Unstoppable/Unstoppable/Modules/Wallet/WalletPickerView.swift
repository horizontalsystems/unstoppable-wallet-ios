import MarketKit
import SwiftUI

// Reusable wallet picker; caller owns the navigation.
struct WalletPickerView: View {
    @ObservedObject var viewModel: SendTokenListViewModel
    @Binding var searchText: String
    @Binding var blockchain: Blockchain?

    let onSelect: (Wallet) -> Void
    let onFailed: ((Wallet, AdapterState) -> Void)?

    var body: some View {
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
                        WalletListItemView(
                            item: item,
                            balancePrimaryValue: viewModel.balancePrimaryValue,
                            balanceHidden: viewModel.balanceHidden,
                            amountRounding: viewModel.amountRounding,
                            subtitleMode: .coinName,
                            isReachable: viewModel.isReachable
                        ) {
                            onSelect(item.wallet)
                        } failedAction: {
                            onFailed?(item.wallet, item.state)
                        }
                    }
                }
            }
        }
    }

    private var filteredItems: [WalletListViewModel.Item] {
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

    private var blockchains: [Blockchain] {
        Array(Set(viewModel.itemsWithOptions.map(\.wallet.token.blockchain))).sorted { $0.type.order < $1.type.order }
    }
}

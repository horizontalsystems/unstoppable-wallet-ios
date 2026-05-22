import MarketKit
import SwiftUI
import WalletCore

// Reusable wallet picker; caller owns the navigation.
struct WalletPickerView: View {
    @ObservedObject var viewModel: SendTokenListViewModel
    @Binding var searchText: String
    @Binding var blockchainFilter: SendTokenListViewModel.BlockchainFilter?

    let onSelect: (Wallet) -> Void
    let onFailed: ((Wallet, AdapterState) -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if let filter = blockchainFilter {
                let blockchains = viewModel.availableBlockchains
                ScrollableTabHeaderView(
                    tabs: ["filter.all".localized] + blockchains.map(\.name),
                    currentTabIndex: Binding(
                        get: {
                            if let blockchain = filter.blockchain,
                               let index = blockchains.firstIndex(of: blockchain)
                            {
                                return index + 1
                            } else {
                                return 0
                            }
                        },
                        set: { index in
                            if index == 0 {
                                blockchainFilter = .all
                            } else {
                                blockchainFilter = .blockchain(blockchains[index - 1])
                            }
                        }
                    )
                )
            }

            switch viewModel.itemState(searchText: searchText, blockchainFilter: blockchainFilter) {
            case .loading:
                VStack { ProgressView() }.frame(maxHeight: .infinity)
            case .empty:
                PlaceholderViewNew(icon: "warning_filled", subtitle: "alert.not_founded".localized)
            case let .loaded(items):
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

import MarketKit
import SwiftUI

struct ReceiveCoinListView: View {
    @StateObject var viewModel: ReceiveCoinListViewModel

    @Environment(\.presentationMode) private var presentationMode

    @State var path = NavigationPath()

    init(account: Account) {
        let coinProvider = CoinProvider(
            marketKit: Core.shared.marketKit,
            walletManager: Core.shared.walletManager,
            accountType: account.type
        )
        let service = ReceiveCoinListService(provider: coinProvider, accountType: account.type)
        _viewModel = StateObject(wrappedValue: ReceiveCoinListViewModel(account: account, service: service))
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView(style: .list) {
                ZStack {
                    ThemeList {
                        ListForEach(viewModel.viewItems) { viewItem in
                            cell(viewItem: viewItem)
                        }
                    }

                    if !viewModel.searchText.isEmpty, viewModel.viewItems.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "alert.not_founded".localized)
                    }
                }
            }
            .navigationTitle("balance.receive".localized)
            .searchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized)
            .navigationDestination(for: FullCoin.self) { fullCoin in
                ReceiveModule.view(account: viewModel.account, fullCoin: fullCoin, path: $path, onDismiss: {
                    presentationMode.wrappedValue.dismiss()
                })
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }

    @ViewBuilder private func cell(viewItem: ReceiveCoinListViewModel.ViewItem) -> some View {
        Cell(
            left: {
                CoinIconView(coin: viewItem.coin)
            },
            middle: {
                MultiText(title: viewItem.title, subtitle: viewItem.description)
            },
            right: {
                Image.disclosureIcon
            },
            action: {
                guard let fullCoin = viewModel.fullCoin(uid: viewItem.uid) else {
                    return
                }

                viewModel.prepareEnable(fullCoin: fullCoin)
                path.append(fullCoin)
            }
        )
    }
}

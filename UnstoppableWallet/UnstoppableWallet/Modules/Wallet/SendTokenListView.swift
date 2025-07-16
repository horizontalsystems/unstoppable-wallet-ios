import SwiftUI

struct SendTokenListView: View {
    @StateObject private var viewModel: SendTokenListViewModel

    @State private var path = NavigationPath()
    @State private var searchText = ""

    @Binding var isPresented: Bool

    init(options: SendTokenListViewModel.SendOptions = .init(), isPresented: Binding<Bool>) {
        _viewModel = .init(wrappedValue: SendTokenListViewModel(options: options))
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack(path: $path) {
            ThemeView {
                VStack(spacing: 0) {
                    SearchBar(text: $searchText, prompt: "add_token.coin_name".localized)

                    let items = filteredItems

                    ThemeList(bottomSpacing: .margin16) {
                        ForEach(items) { item in
                            VStack(spacing: 0) {
                                if items.first?.id == item.id {
                                    HorizontalDivider()
                                }

                                WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, subtitleMode: .coinName) {
                                    path.append(item.wallet)
                                    stat(page: .sendTokenList, event: .openSend(token: item.wallet.token))
                                } failedAction: {
                                    Coordinator.shared.presentBalanceError(wallet: item.wallet, state: item.state)
                                }

                                HorizontalDivider()
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .navigationDestination(for: Wallet.self) { wallet in
                SendAddressView(wallet: wallet, address: viewModel.options.address, amount: viewModel.options.amount, isPresented: $isPresented)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("button.cancel".localized) {
                        isPresented = false
                    }
                }
            }
            .navigationTitle("send.send".localized)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var filteredItems: [WalletListViewModel.Item] {
        let text = searchText.trimmingCharacters(in: .whitespaces)

        if text.isEmpty {
            return viewModel.itemsWithOptions
        } else {
            return viewModel.itemsWithOptions.filter { item in
                item.wallet.token.coin.name.localizedCaseInsensitiveContains(text) || item.wallet.token.coin.code.localizedCaseInsensitiveContains(text)
            }
        }
    }
}

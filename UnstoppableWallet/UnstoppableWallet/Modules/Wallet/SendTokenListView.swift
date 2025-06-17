import SwiftUI

struct SendTokenListView: View {
    @StateObject private var viewModel = SendTokenListViewModel()
    @StateObject private var balanceErrorViewModifierModel = BalanceErrorViewModifierModel()

    @State private var path = NavigationPath()
    @State private var searchText = ""

    @Binding var isPresented: Bool

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
                                } failedAction: {
                                    balanceErrorViewModifierModel.handle(wallet: item.wallet, state: item.state)
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
                SendAddressView(wallet: wallet)
            }
            .modifier(BalanceErrorViewModifier(viewModel: balanceErrorViewModifierModel))
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
            return viewModel.items
        } else {
            return viewModel.items.filter { item in
                item.wallet.token.coin.name.localizedCaseInsensitiveContains(text) || item.wallet.token.coin.code.localizedCaseInsensitiveContains(text)
            }
        }
    }
}

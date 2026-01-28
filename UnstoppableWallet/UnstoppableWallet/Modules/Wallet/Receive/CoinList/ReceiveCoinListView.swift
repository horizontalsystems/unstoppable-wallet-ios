import MarketKit
import SwiftUI

struct ReceiveCoinListView: View {
    @StateObject var viewModel: ReceiveCoinListViewModel

    @Environment(\.presentationMode) private var presentationMode
    @FocusState var searchFocused: Bool

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

                    if viewModel.viewItems.isEmpty {
                        PlaceholderViewNew(icon: "warning_filled", subtitle: "alert.not_founded".localized)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    BottomSearchBar(text: $viewModel.searchText, prompt: "placeholder.search".localized, focused: $searchFocused)
                }
            }
            .navigationTitle("balance.receive".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: FullCoin.self) { fullCoin in
                ReceiveModule.view(account: viewModel.account, fullCoin: fullCoin, path: $path, onDismiss: {
                    presentationMode.wrappedValue.dismiss()
                })
            }
            .onChange(of: viewModel.enableTokenWithBirthday) { token in
                if let token {
                    showBirthdayEnableSheet(token: token)
                }
            }
            .onChange(of: viewModel.pushCoinUid) { uid in
                if let uid {
                    push(uid: uid)
                    viewModel.pushCoinUid = nil
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("button.cancel".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .accentColor(.themeGray)
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
                push(uid: viewItem.uid)
            }
        )
    }

    private func push(uid: String) {
        viewModel.handleAfterEnable(uid: uid) {
            path.append($0)
        }
    }

    private func showBirthdayEnableSheet(token: Token) {
        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BottomSheetView(
                items: [
                    .title(title: token.coin.name),
                    .text(text: "deposit.restore.enabled.description".localized(token.coin.code)),
                    .buttonGroup(.init(buttons: [
                        .init(style: .yellow, title: "deposit.restore.enabled.already_own".localized, action: {
                            isPresented.wrappedValue = false
                            viewModel.enableTokenWithBirthday = nil

                            showBirthdayInput(token: token)
                        }),
                        .init(style: .transparent, title: "deposit.restore.enabled.dont_have".localized, action: {
                            isPresented.wrappedValue = false
                            viewModel.enableTokenWithBirthday = nil

                            viewModel.createWallet(token: token, height: nil)
                        }),
                    ])),
                ],
            )
        }
    }

    private func showBirthdayInput(token: Token) {
        let blockchain = token.blockchain

        guard let provider = BirthdayInputProviderFactory.provider(blockchainType: blockchain.type) else {
            return
        }

        Coordinator.shared.present { _ in
            BirthdayInputView(blockchain: blockchain, provider: provider, onEnterBirthdayHeight: { height in
                DispatchQueue.main.async {
                    viewModel.createWallet(token: token, height: height)
                }
            })
        }
    }
}

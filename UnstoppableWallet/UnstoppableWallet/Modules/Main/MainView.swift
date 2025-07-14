import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModelNew()
    @StateObject var badgeViewModel = MainBadgeViewModel()
    @StateObject var walletViewModel = WalletViewModelNew()
    @StateObject var transactionsViewModel = TransactionsViewModelNew()

    @StateObject private var frameCalculator = TabBarFrameCalculator()

    @State private var path = NavigationPath()

    @State private var backupAccount: Account?

    var body: some View {
        ThemeNavigationStack(path: $path) {
            TabView(selection: $viewModel.selectedTab) {
                Group {
                    if viewModel.showMarket {
                        MarketView()
                            .tabItem {
                                Image("market_2_24").renderingMode(.template)
                            }
                            .tag(MainViewModelNew.Tab.markets)
                    }

                    WalletView(viewModel: walletViewModel, path: $path)
                        .tabItem {
                            Image("filled_wallet_24").renderingMode(.template)
                        }
                        .tag(MainViewModelNew.Tab.wallet)

                    MainTransactionsView(transactionsViewModel: transactionsViewModel)
                        .tabItem {
                            Image("filled_transaction_2n_24").renderingMode(.template)
                        }
                        .tag(MainViewModelNew.Tab.transactions)

                    MainSettingsView()
                        .tabItem {
                            Image("filled_settings_2_24").renderingMode(.template)
                        }
                        .tag(MainViewModelNew.Tab.settings)
                }
                .toolbarBackground(.hidden, for: .tabBar)
            }
            .onAppear {
                calculateTabFrames()
            }
            .navigationDestination(for: Wallet.self) { wallet in
                WalletTokenModule.view(wallet: wallet)
            }
            .tint(.themeJacob)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar() }
            .overlay(
                TabBarBadgeOverlay(
                    frameCalculator: frameCalculator,
                    badgeText: badgeViewModel.badge,
                    targetTabIndex: .last
                )
            )
        }
        .onAppear {
            viewModel.handleNextAlert()
        }
        .modifier(DeepLinkViewModifier())
        .modifier(CoordinatorViewModifier())
    }

    private func calculateTabFrames() {
        DispatchQueue.main.async {
            frameCalculator.calculateFrames()
        }
    }

    @ToolbarContentBuilder func toolbar() -> some ToolbarContent {
        switch viewModel.selectedTab {
        case .markets:
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Coordinator.shared.present { isPresented in
                        MarketAdvancedSearchView(isPresented: isPresented)
                    }
                    stat(page: .markets, event: .open(page: .advancedSearch))
                }) {
                    Image("manage_2_24")
                        .renderingMode(.template)
                        .foregroundColor(.themeGray)
                }
            }
        case .wallet:
            if walletViewModel.account != nil {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Coordinator.shared.present { isPresented in
                            ThemeNavigationStack { ManageAccountsView(isPresented: isPresented) }
                        }
                        stat(page: .balance, event: .open(page: .manageWallets))
                    }) {
                        Image("switch_wallet_24")
                            .renderingMode(.template)
                            .foregroundColor(.themeGray)
                    }
                }
            }
        case .transactions:
            ToolbarItem(placement: .navigationBarLeading) {
                if transactionsViewModel.syncing {
                    ProgressView()
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Coordinator.shared.present { isPresented in
                        TransactionFilterView(transactionsViewModel: transactionsViewModel, isPresented: isPresented)
                    }
                    stat(page: .transactions, event: .open(page: .transactionFilter))
                }) {
                    ZStack {
                        Image("manage_2_24").themeIcon(color: .themeGray)

                        if transactionsViewModel.transactionFilter.hasChanges {
                            VStack {
                                HStack {
                                    Spacer()
                                    Circle().fill(Color.red).frame(width: 8, height: 8)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 28, height: 28)
                }
            }
        case .settings:
            ToolbarItem(placement: .navigationBarTrailing) {}
        }
    }

    var title: String {
        switch viewModel.selectedTab {
        case .markets:
            return "market.title".localized
        case .wallet:
            return walletViewModel.account?.name ?? AppConfig.appName
        case .transactions:
            return "transactions.title".localized
        case .settings:
            return "settings.title".localized
        }
    }
}

struct AccountsLostView: View {
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            icon: .warning,
            title: "lost_accounts.warning_title".localized,
            items: [
                .text(text: "lost_accounts.warning_message".localized),
            ],
            buttons: [
                .init(style: .yellow, title: "button.ok".localized) {
                    isPresented = false
                },
            ],
            isPresented: $isPresented
        )
    }
}

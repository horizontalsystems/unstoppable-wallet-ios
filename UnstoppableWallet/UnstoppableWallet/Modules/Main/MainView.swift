import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModelNew()
    @StateObject var badgeViewModel = MainBadgeViewModel()
    @StateObject var walletViewModel = WalletViewModelNew()
    @StateObject var transactionsViewModel = TransactionsViewModelNew()

    @State private var path = NavigationPath()

    @State private var advancedSearchPresented = false
    @State private var manageAccountsPresented = false
    @State private var transactionFilterPresented = false

    @State private var backupAccount: Account?

    var body: some View {
        ThemeNavigationStack(path: $path) {
            TabView(selection: $viewModel.selectedTab) {
                Group {
                    if viewModel.showMarket {
                        MarketView()
                            .tabItem {
                                Image("market_2_24").renderingMode(.template)
                                Text("market.tab_bar_item".localized)
                            }
                            .tag(MainViewModelNew.Tab.markets)
                    }

                    WalletView(viewModel: walletViewModel, path: $path)
                        .tabItem {
                            Image("filled_wallet_24").renderingMode(.template)
                            Text("balance.tab_bar_item".localized)
                        }
                        .tag(MainViewModelNew.Tab.wallet)

                    MainTransactionsView(transactionsViewModel: transactionsViewModel)
                        .tabItem {
                            Image("filled_transaction_2n_24").renderingMode(.template)
                            Text("transactions.tab_bar_item".localized)
                        }
                        .tag(MainViewModelNew.Tab.transactions)

                    MainSettingsView()
                        .tabItem {
                            Image("filled_settings_2_24").renderingMode(.template)
                            Text("settings.tab_bar_item".localized)
                        }
                        .tag(MainViewModelNew.Tab.settings)
                        .badge(badgeViewModel.badge)
                }
                .toolbarBackground(.hidden, for: .tabBar)
            }
            .navigationDestination(for: Wallet.self) { wallet in
                WalletTokenModule.view(wallet: wallet)
            }
            .tint(.themeJacob)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar() }
        }
        .onAppear {
            viewModel.handleNextAlert()
        }
        .sheet(isPresented: $advancedSearchPresented) {
            MarketAdvancedSearchView(isPresented: $advancedSearchPresented)
        }
        .sheet(isPresented: $manageAccountsPresented) {
            ThemeNavigationStack {
                ManageAccountsView(isPresented: $manageAccountsPresented) { account in
                    manageAccountsPresented = false
                    backupAccount = account
                }
                .onFirstAppear {
                    stat(page: .balance, event: .open(page: .manageWallets))
                }
            }
        }
        .sheet(isPresented: $transactionFilterPresented) {
            TransactionFilterView(transactionsViewModel: transactionsViewModel)
        }
        .sheet(item: $viewModel.releaseNotesUrl) { url in
            MarkdownModule.gitReleaseNotesMarkdownView(url: url, presented: true)
                .onFirstAppear {
                    stat(page: .main, event: .open(page: .whatsNews))
                }
                .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.jailbreakPresented) {
            JailbreakView(isPresented: $viewModel.jailbreakPresented)
        }
        .bottomSheet(isPresented: $viewModel.switchAccountPresented) {
            SwitchAccountView()
        }
        .bottomSheet(isPresented: $viewModel.accountsLostPresented) {
            BottomSheetView(
                icon: .warning,
                title: "lost_accounts.warning_title".localized,
                items: [
                    .text(text: "lost_accounts.warning_message".localized),
                ],
                buttons: [
                    .init(style: .yellow, title: "button.ok".localized) {
                        viewModel.accountsLostPresented = false
                    },
                ],
                onDismiss: { viewModel.accountsLostPresented = false }
            )
        }
        .modifier(BackupRequiredViewModifier.backupPromptAfterCreate(account: $backupAccount))
    }

    @ToolbarContentBuilder func toolbar() -> some ToolbarContent {
        switch viewModel.selectedTab {
        case .markets:
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    advancedSearchPresented = true
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
                        manageAccountsPresented = true
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
                    transactionFilterPresented = true
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

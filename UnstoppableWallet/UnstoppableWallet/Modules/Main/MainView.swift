import SwiftUI

struct MainView: View {
    @StateObject var viewModel = MainViewModel()
    @StateObject var badgeViewModel = MainBadgeViewModel()
    @StateObject var walletViewModel = WalletViewModel()
    @StateObject var transactionsViewModel = TransactionsViewModel()

    @State private var path = NavigationPath()

    @State private var backupAccount: Account?

    var body: some View {
        ThemeNavigationStack(path: $path) {
            TabView(selection: $viewModel.selectedTab) {
                if viewModel.showMarket {
                    MarketView()
                        .tabItem { Label("", image: "market_filled") }
                        .tag(MainViewModel.Tab.markets)
                        .tint(.themeLeah)
                }

                WalletView(viewModel: walletViewModel, path: $path)
                    .tabItem { Label("", image: "wallet_filled") }
                    .tag(MainViewModel.Tab.wallet)
                    .tint(.themeLeah)

                MultiSwapView()
                    .tabItem { Label("", image: "swap_filled") }
                    .tag(MainViewModel.Tab.swap)
                    .tint(.themeLeah)

                MainSettingsView()
                    .tabItem { Label("", image: "settings_filled") }
                    .tag(MainViewModel.Tab.settings)
                    .badge(badgeViewModel.badge.map { _ in "1" })
                    .tint(.themeLeah)
            }
            .tint(.themeJacob)
            .navigationDestination(for: Wallet.self) { wallet in
                WalletTokenModule.view(wallet: wallet)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar() }
        }
    }

    @ToolbarContentBuilder func toolbar() -> some ToolbarContent {
        switch viewModel.selectedTab {
        case .markets:
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Coordinator.shared.present { isPresented in
                        MarketSearchView(isPresented: isPresented)
                    }
                    stat(page: .markets, event: .open(page: .marketSearch))
                }) {
                    Image("search")
                }
            }
        case .wallet:
            if walletViewModel.account != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Coordinator.shared.present { isPresented in
                            ThemeNavigationStack { ManageAccountsView(isPresented: isPresented) }
                        }
                        stat(page: .balance, event: .open(page: .manageWallets))
                    }) {
                        Image("wallet_change")
                    }
                }

                if walletViewModel.totalItem.state == .syncing {
                    ToolbarItem(placement: .navigationBarLeading) {
                        ProgressView(value: 0.55)
                            .progressViewStyle(DeterminiteSpinnerStyle())
                            .frame(size: 24)
                            .spinning()
                    }
                }

                if walletViewModel.buttonHidden {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            Coordinator.shared.present { isPresented in
                                ScanQrViewNew(reportAfterDismiss: true, isPresented: isPresented) { text in
                                    walletViewModel.process(scanned: text)
                                }
                                .ignoresSafeArea()
                            }
                            stat(page: .balance, event: .open(page: .scanQrCode))
                        }) {
                            Image("scan")
                        }
                    }
                }
            }
        case .swap:
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Coordinator.shared.present { isPresented in
                        SwapHistoryView(isPresented: isPresented)
                    }
                }) {
                    Image("clock")
                }
            }
        case .transactions:
            ToolbarItem(placement: .primaryAction) {
                Button(action: {
                    Coordinator.shared.present { isPresented in
                        TransactionFilterView(transactionsViewModel: transactionsViewModel, isPresented: isPresented)
                    }
                    stat(page: .transactions, event: .open(page: .transactionFilter))
                }) {
                    Image("manage_2_24")
                        .modifier(ToolbarBadgeModifier(visible: transactionsViewModel.transactionFilter.hasChanges))
                }
            }

            ToolbarItem(placement: .navigationBarLeading) {
                if transactionsViewModel.syncing {
                    ProgressView(value: 0.55)
                        .progressViewStyle(DeterminiteSpinnerStyle())
                        .frame(size: 24)
                        .spinning()
                }
            }
        case .settings:
            ToolbarItem {}
        }
    }

    var title: String {
        switch viewModel.selectedTab {
        case .markets:
            return "market.title".localized
        case .wallet:
            return walletViewModel.account?.name ?? "balance.title".localized
        case .swap:
            return "swap.title".localized
        case .transactions:
            return "transactions.title".localized
        case .settings:
            return "settings.title".localized
        }
    }
}

extension MainView {
    struct BadgeView: View {
        private let emptyBadgeSize: CGFloat = 10
        @State private var textHeight: CGFloat = 0

        let badge: String

        var body: some View {
            if badge.isEmpty {
                Circle()
                    .foregroundStyle(Color.themeRed)
                    .frame(width: emptyBadgeSize, height: emptyBadgeSize)
            } else {
                Text(badge)
                    .font(.themeMicro)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .frame(minWidth: textHeight)
                    .background(
                        GeometryReader { geometry in
                            Color.themeRed
                                .onAppear {
                                    textHeight = geometry.size.height
                                }
                        }
                    )
                    .clipShape(Capsule())
            }
        }
    }
}

struct AccountsLostView: View {
    let records: [AccountRecord]
    @Binding var isPresented: Bool

    var body: some View {
        BottomSheetView(
            items: [
                .title(icon: ThemeImage.warning, title: "lost_accounts.warning_title".localized),
                .text(text: "lost_accounts.warning_message".localized(records.map { "- \($0.name)" }.joined(separator: "\n"))),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "button.i_understand".localized) {
                        isPresented = false
                    },
                ])),
            ],
        )
    }
}

struct ToolbarBadgeModifier: ViewModifier {
    let visible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if visible {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: 3, y: -3)
                }
            }
    }
}

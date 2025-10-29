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
            VStack(spacing: 0) {
                TabView(selection: $viewModel.selectedTab) {
                    Group {
                        if viewModel.showMarket {
                            MarketView().tag(MainViewModel.Tab.markets)
                        }

                        WalletView(viewModel: walletViewModel, path: $path).tag(MainViewModel.Tab.wallet)
                        MainTransactionsView(transactionsViewModel: transactionsViewModel).tag(MainViewModel.Tab.transactions)
                        MainSettingsView().tag(MainViewModel.Tab.settings)
                    }
                    .toolbar(.hidden, for: .tabBar)
                }

                HStack(spacing: 0) {
                    ForEach(viewModel.tabs, id: \.self) { tab in
                        ZStack {
                            Image(tab.image).icon(colorStyle: viewModel.selectedTab == tab ? .yellow : .secondary)

                            if tab == MainViewModel.Tab.settings, let badge = badgeViewModel.badge {
                                BadgeView(badge: badge)
                                    .offset(x: 12, y: -12)
                            }
                        }
                        .padding(.vertical, .margin16)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, .margin16)
                .background(Color.themeBlade)
            }
            .ignoresSafeArea(.keyboard)
            .navigationDestination(for: Wallet.self) { wallet in
                WalletTokenModule.view(wallet: wallet)
            }
            .tint(.themeJacob)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar() }
        }
        .modifier(CoordinatorViewModifier())
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
                        Image("wallet_change")
                    }
                }

                if walletViewModel.totalItem.state == .syncing {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        ProgressView(value: 0.55)
                            .progressViewStyle(DeterminiteSpinnerStyle())
                            .frame(width: 20, height: 20)
                            .spinning()
                    }
                }

                if walletViewModel.buttonHidden {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            Coordinator.shared.present { _ in
                                ScanQrViewNew(reportAfterDismiss: true, pasteEnabled: true) { text in
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
            return walletViewModel.account?.name ?? "balance.title".localized
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
        BottomSheetView.instance(
            icon: .warning,
            title: "lost_accounts.warning_title".localized,
            items: [
                .text(text: "lost_accounts.warning_message".localized(records.map { "- \($0.name)" }.joined(separator: "\n"))),
                .buttonGroup(.init(buttons: [
                    .init(style: .yellow, title: "button.i_understand".localized) {
                        isPresented = false
                    },
                ])),
            ],
            isPresented: $isPresented
        )
    }
}

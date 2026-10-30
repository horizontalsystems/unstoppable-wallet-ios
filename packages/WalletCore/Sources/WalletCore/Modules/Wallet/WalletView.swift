import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModel
    @StateObject var accountWarningViewModel = AccountWarningViewModel(ignoreType: .always)

    @Binding var selectedWallet: Wallet?

    var body: some View {
        Group {
            if let account = viewModel.account {
                if viewModel.noTokens {
                    emptyView(account: account)
                } else {
                    listView(account: account)
                }
            } else {
                ThemeView {
                    PlaceholderWrapperViewNew {
                        VStack(spacing: .margin24) {
                            Image("wallet_add").icon(size: .iconSize72).padding(16)

                            AddWalletRowsView(
                                onNewWallet: {
                                    Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                        ThemeNavigationStack {
                                            NewWalletTypeView(isPresented: isPresented, showClose: true)
                                        }
                                    }
                                },
                                onExistingWallet: {
                                    Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                        ThemeNavigationStack {
                                            RestoreTypeView(isPresented: isPresented, showClose: true)
                                        }
                                    }
                                },
                                onWatchWallet: {
                                    Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                        ThemeNavigationStack {
                                            WatchView(isPresented: isPresented, showClose: true)
                                        }
                                    }
                                    stat(page: .addWallet, event: .open(page: .watchWallet))
                                }
                            )
                            .padding(.horizontal, .margin16)
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }

    private func listView(account: Account) -> some View {
        ThemeView(style: .list) {
            ScrollViewReader { proxy in
                ThemeList(bottomSpacing: .margin16) {
                    topView(account: account)
                        .listRowBackground(Color.themeTyler)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .themeListTopView()

                    AccountWarningView(viewModel: accountWarningViewModel)
                        .listRowBackground(Color.themeTyler)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .padding(.horizontal, .margin16)
                        .padding(.top, .margin8)
                        .padding(.bottom, .margin12)

                    Section {
                        itemsView()
                    } header: {
                        headerView(account: account)
                    }

                    VStack {
                        ThemeButton(text: "button.add".localized, icon: "plus", spinner: false, style: .secondary, mode: .solid, size: .small) {
                            onTapManage()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .padding(.horizontal, .margin16)
                    .padding(.top, .margin24)
                }
                .animation(.default, value: accountWarningViewModel.item)
                .refreshable {
                    viewModel.refresh()
                    await Task { try? await Task.sleep(seconds: 1) }.value
                }
                .onChange(of: viewModel.sortType) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                .themeListScrollHeader()
            }
        }
    }

    private func topView(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ThemeText(primaryValue, style: .title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.onTapAmount()
                        HapticGenerator.instance.notification(.feedback(.soft))
                    }

                ThemeText(secondaryValue, style: .body, colorStyle: .secondary)
                    .onTapGesture {
                        viewModel.onTapConvertedAmount()
                        HapticGenerator.instance.notification(.feedback(.soft))
                    }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(TestTags.balanceTotal)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)

            if account.watchAccount, let address = account.type.watchAddress {
                Cell(
                    left: {
                        Image("binocular").icon(size: 24)
                    },
                    middle: {
                        MiddleTextIcon(text: "balance.watch_wallet".localized)
                    },
                    right: {
                        RightButtonText(text: address.shortened, icon: "copy_filled") {
                            CopyHelper.copyAndNotify(value: address)
                        }
                    }
                )
            } else if !viewModel.buttonHidden {
                let buttons = viewModel.buttons

                HStack(spacing: 0) {
                    ForEach(buttons, id: \.self) { button in
                        buttonView(button: button)

                        if button != buttons.last {
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, 24)
                .padding(.horizontal, 16)
            }
        }
    }

    private func emptyView(account: Account) -> some View {
        ThemeView {
            VStack(spacing: 0) {
                topView(account: account)

                PlaceholderViewNew(icon: "wallet_in", subtitle: "balance.no_tokens".localized) {
                    ThemeButton(text: "add_token.title".localized, mode: .transparent, size: .small) {
                        onTapManage()
                    }
                }
                .background(Color.themeLawrence)
            }
        }
    }

    private func itemsView() -> some View {
        ListForEachIdentifiable(viewModel.items) { item in
            WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, amountRounding: viewModel.amountRounding, subtitleMode: .price, isReachable: viewModel.isReachable) {
                selectedWallet = item.wallet
            } failedAction: {
                Coordinator.shared.presentBalanceError(wallet: item.wallet, state: item.state)
            }
            .swipeActions {
                Button {
                    viewModel.onDisable(wallet: item.wallet)
                } label: {
                    Image(uiImage: UIImage(named: "trash")!.withTintColor(UIColor(Color.themeLeah), renderingMode: .alwaysOriginal))
                }
                .tint(.themeBlade)
            }
            .contextMenu {
                if !item.wallet.account.watchAccount {
                    Button {
                        Coordinator.shared.present { isPresented in
                            PreSendViewWrapper(wallet: item.wallet, isPresented: isPresented)
                        }
                        stat(page: .tokenPage, event: .openSend(token: item.wallet.token))
                    } label: {
                        Label("balance.send".localized, image: "arrow_m_up")
                    }
                }
                if let addressAdapter = Core.shared.adapterManager.adapter(for: item.wallet),
                   let depositAdapter = addressAdapter as? IDepositAdapter
                {
                    Button {
                        copyAddressIfBackedUp(address: depositAdapter.receiveAddress.address)
                    } label: {
                        Text("balance.copy_address".localized)
                        Text(depositAdapter.receiveAddress.address.shortened)
                        Image("copy")
                    }
                }
                if !item.wallet.account.watchAccount, viewModel.swapEnabled {
                    Button {
                        Coordinator.shared.present { _ in
                            RegularMultiSwapView(token: item.wallet.token)
                        }
                        stat(page: .balance, event: .open(page: .swap))
                    } label: {
                        Label("balance.swap".localized, image: "swap_e")
                    }
                }
                Button {
                    Coordinator.shared.presentCoinPage(coin: item.wallet.coin, page: .tokenPage)
                } label: {
                    Label("balance.coin_info".localized, image: "chart")
                }
                Button {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        viewModel.onDisable(wallet: item.wallet)
                    }
                } label: {
                    Label("balance.hide_coin".localized, image: "minus_e")
                }
            }
        }
        .tint(.themeLeah)
    }

    private func copyAddressIfBackedUp(address: String) {
        CopyHelper.copyAndNotify(value: address)
    }

    private func headerView(account _: Account) -> some View {
        ListHeader {
            DropdownButton(text: viewModel.sortType.title) {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: "balance.sort.header".localized,
                        viewItems: WalletSorter.SortType.allCases.map { .init(text: $0.title, selected: viewModel.sortType == $0) },
                        onSelect: { index in
                            viewModel.sortType = WalletSorter.SortType.allCases[index]
                        },
                        isPresented: isPresented
                    )
                }
            }

            IconButton(icon: "manage", style: .secondary, size: .small) {
                onTapManage()
            }
            .accessibilityIdentifier(TestTags.balanceManageCoins)

            Spacer()

            if !viewModel.isReachable {
                ThemeText("alert.no_internet".localized, style: .subheadSB, colorStyle: .red)
            } else if viewModel.totalItem.state == .syncing {
                ProgressView(value: 0.6)
                    .progressViewStyle(DeterminiteSpinnerStyle())
                    .frame(size: 20)
                    .spinning()
                    .accessibilityIdentifier(TestTags.balanceSyncIndicator)
            }
        }
    }

    private func onTapManage() {
        if let account = viewModel.account {
            Coordinator.shared.present { isPresented in
                ManageWalletsView(account: account, isPresented: isPresented).ignoresSafeArea()
            }
            stat(page: .balance, event: .open(page: .coinManager))
        }
    }

    private func identifier(button: WalletButton) -> String? {
        switch button {
        case .scan: return TestTags.balanceScan
        case .receive: return TestTags.balanceReceive
        case .send: return TestTags.balanceSend
        case .swap: return TestTags.balanceSwap
        case .chart: return nil
        }
    }

    private func buttonView(button: WalletButton) -> some View {
        WalletButtonView(icon: button.icon, title: button.title, accent: button.accent, identifier: identifier(button: button)) {
            switch button {
            case .send:
                Coordinator.shared.present { isPresented in
                    SendTokenListView(isPresented: isPresented)
                }
                stat(page: .balance, event: .open(page: .sendTokenList))
            case .receive: viewModel.onTapReceive()
            case .swap:
                Coordinator.shared.present { _ in
                    RegularMultiSwapView()
                }
                stat(page: .balance, event: .open(page: .swap))
            case .scan:
                Coordinator.shared.present { isPresented in
                    ScanQrView(reportAfterDismiss: true, isPresented: isPresented) { text in
                        viewModel.process(scanned: text)
                    }
                    .ignoresSafeArea()
                }
                stat(page: .balance, event: .open(page: .scanQrCode))
            default: ()
            }
        }
    }

    private var primaryValue: CustomStringConvertible {
        if viewModel.balanceHidden {
            return BalanceHiddenManager.placeholder
        }

        var colorStyle: ColorStyle = .primary
        var dimmed = false

        if viewModel.isReachable {
            switch viewModel.totalItem.state {
            case .synced:
                ()
            case .expired:
                colorStyle = .secondary
            case .syncing:
                ()
//                dimmed = true     // remove dimmed state for now
            }
        }

        return ComponentText(
            text: ValueFormatter.instance.formatWith(rounding: viewModel.amountRounding, currencyValue: viewModel.totalItem.currencyValue) ?? String.placeholder,
            colorStyle: colorStyle,
            dimmed: dimmed
        )
    }

    private var secondaryValue: CustomStringConvertible {
        if viewModel.balanceHidden {
            return " "
        }
//
//        var dimmed = false
//        if viewModel.totalItem.state == .syncing {
//            dimmed = true
//        }

        return ComponentText(
            text: viewModel.totalItem.convertedValue.flatMap { $0.formattedWith(rounding: viewModel.amountRounding) }.map { "≈ \($0)" } ?? String.placeholder,
            dimmed: false
        )
    }
}

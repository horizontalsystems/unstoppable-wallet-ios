import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModel
    @StateObject var accountWarningViewModel = AccountWarningViewModel(ignoreType: .always)

    @Binding var path: NavigationPath

    var body: some View {
        Group {
            if let account = viewModel.account {
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
                        }
                        .animation(.default, value: accountWarningViewModel.item)
                        .refreshable {
                            await viewModel.refresh()
                        }
                        .onChange(of: viewModel.sortType) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                        .themeListScrollHeader()
                    }
                }
            } else {
                ThemeView {
                    PlaceholderViewNew(icon: "wallet_add", layoutType: .middle) {
                        VStack(spacing: .margin12) {
                            ThemeButton(text: "onboarding.balance.create".localized) {
                                Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                    CreateAccountView(isPresented: isPresented)
                                } onPresent: {
                                    stat(page: .balance, event: .open(page: .newWallet))
                                }
                            }

                            ThemeButton(text: "onboarding.balance.import".localized, style: .secondary) {
                                Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                    RestoreTypeView(type: .wallet, isPresented: isPresented)
                                } onPresent: {
                                    stat(page: .balance, event: .open(page: .importWallet))
                                }
                            }

                            ThemeButton(text: "onboarding.balance.watch".localized, style: .secondary, mode: .transparent) {
                                Coordinator.shared.present { isPresented in
                                    WatchView(isPresented: isPresented)
                                }
                                stat(page: .balance, event: .open(page: .watchWallet))
                            }
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

    @ViewBuilder private func topView(account: Account) -> some View {
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
                    },
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

    @ViewBuilder private func itemsView() -> some View {
        ListForEach(viewModel.items) { item in
            WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, amountRounding: viewModel.amountRounding, subtitleMode: .price, isReachable: viewModel.isReachable) {
                path.append(item.wallet)
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
                            ThemeNavigationStack {
                                SendAddressView(wallet: item.wallet, isPresented: isPresented)
                            }
                        }
                        stat(page: .tokenPage, event: .openSend(token: item.wallet.token))
                    } label: {
                        Label("balance.send".localized, image: "arrow_m_up")
                    }
                }
                let addressProvider = ReceiveAddressModule.addressProvider(wallet: item.wallet)
                if addressProvider.address != nil {
                    Button {
                        if let address = addressProvider.address {
                            CopyHelper.copyAndNotify(value: address)
                        }
                    } label: {
                        Label("balance.copy_address".localized, image: "copy")
                    }
                }
                if !item.wallet.account.watchAccount, item.wallet.token.swappable {
                    Button {
                        Coordinator.shared.present { _ in
                            MultiSwapView(token: item.wallet.token)
                        }
                        stat(page: .tokenPage, event: .open(page: .swap))
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
    }

    @ViewBuilder private func headerView(account _: Account) -> some View {
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
                if let account = viewModel.account {
                    Coordinator.shared.present { _ in
                        ManageWalletsView(account: account).ignoresSafeArea()
                    }
                    stat(page: .balance, event: .open(page: .coinManager))
                }
            }

            Spacer()

            if !viewModel.isReachable {
                ThemeText("alert.no_internet".localized, style: .subheadSB, colorStyle: .red)
            }
        }
    }

    @ViewBuilder private func buttonView(button: WalletButton) -> some View {
        WalletButtonView(icon: button.icon, title: button.title, accent: button.accent) {
            switch button {
            case .send:
                Coordinator.shared.present { isPresented in
                    SendTokenListView(isPresented: isPresented)
                }
                stat(page: .balance, event: .open(page: .sendTokenList))
            case .receive: viewModel.onTapReceive()
            case .swap:
                Coordinator.shared.present { _ in
                    MultiSwapView()
                }
                stat(page: .balance, event: .open(page: .swap))
            case .scan:
                Coordinator.shared.present { _ in
                    ScanQrViewNew(reportAfterDismiss: true, pasteEnabled: true) { text in
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
        switch viewModel.totalItem.state {
        case .synced:
            ()
        case .expired:
            colorStyle = .secondary
        case .syncing:
            dimmed = true
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

        return ComponentText(
            text: viewModel.totalItem.convertedValue.flatMap { $0.formattedWith(rounding: viewModel.amountRounding) }.map { "≈ \($0)" } ?? String.placeholder,
            dimmed: viewModel.totalItem.convertedValueExpired
        )
    }
}

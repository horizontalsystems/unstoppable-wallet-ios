import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModel
    @StateObject var accountWarningViewModel = AccountWarningViewModel(canIgnore: true)

    @Binding var path: NavigationPath

    var body: some View {
        Group {
            if let account = viewModel.account {
                ThemeView(style: .list) {
                    ScrollViewReader { proxy in
                        ThemeList(bottomSpacing: .margin16) {
                            topView()
                                .listRowBackground(Color.themeTyler)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .themeListTopView()

                            AccountWarningView(viewModel: accountWarningViewModel)
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                                .padding(.horizontal, .margin16)
                                .padding(.bottom, .margin16)

                            Section {
                                itemsView()
                            } header: {
                                headerView(account: account)
                            }
                        }
                        .animation(.default, value: viewModel.items)
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
                    PlaceholderViewNew(image: Image("wallet_add"), layoutType: .middle) {
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

    @ViewBuilder private func topView() -> some View {
        VStack(alignment: .leading, spacing: .margin24) {
            VStack(alignment: .leading, spacing: 0) {
                ThemeText(primaryValue, style: .title2)
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

            if !viewModel.buttonHidden, let account = viewModel.account, !account.watchAccount {
                let buttons = viewModel.buttons

                HStack(spacing: 0) {
                    ForEach(buttons, id: \.self) { button in
                        buttonView(button: button)

                        if button != buttons.last {
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding(.vertical, .margin24)
        .padding(.horizontal, .margin16)
    }

    @ViewBuilder private func itemsView() -> some View {
        ListForEach(viewModel.items) { item in
            WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, amountRounding: viewModel.amountRounding, subtitleMode: .price) {
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
        }
    }

    @ViewBuilder private func headerView(account: Account) -> some View {
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

            if account.watchAccount {
                Image("binocular").icon(size: .iconSize20)
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

        return ComponentText(
            text: ValueFormatter.instance.formatWith(rounding: viewModel.amountRounding, currencyValue: viewModel.totalItem.currencyValue) ?? String.placeholder,
            dimmed: viewModel.totalItem.expired
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

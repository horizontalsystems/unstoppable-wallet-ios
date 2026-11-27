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
                    PlaceholderWrapperViewNew(layoutType: .middle) {
                        VStack(spacing: .margin24) {
                            ErrorMessage(icon: "wallet_add", subtitle: "balance.no_wallets".localized)

                            VStack(spacing: .margin12) {
                                ThemeButton(text: "add_wallet.new_wallet".localized) {
                                    Coordinator.shared.present { isPresented in
                                        ThemeNavigationStack {
                                            NewWalletTypeView(isPresented: isPresented, showClose: true)
                                        }
                                    }
                                }
                                .accessibilityIdentifier(TestTags.onboardingNewWallet)

                                ThemeButton(text: "add_wallet.existing_wallet".localized, style: .secondary) {
                                    Coordinator.shared.present { isPresented in
                                        ThemeNavigationStack {
                                            RestoreTypeView(isPresented: isPresented, showClose: true)
                                        }
                                    }
                                }
                                .accessibilityIdentifier(TestTags.onboardingExistingWallet)
                            }
                        }
                        .padding(.horizontal, .margin24)
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
            FloatingButtonListView(isContentReady: !viewModel.items.isEmpty) {
                ThemeList(bottomSpacing: ThemeButton.Size.small.size + 2 * .margin16) {
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

                    itemsView()
                }
                .animation(.default, value: accountWarningViewModel.item)
            } button: {
                addButton
            }
            .refreshable {
                viewModel.refresh()
                await Task { try? await Task.sleep(seconds: 1) }.value
            }
            .themeListScrollHeader()
        }
    }

    private var addButton: some View {
        ThemeButton(text: "button.add".localized, icon: "plus", style: .secondary, mode: .solid, size: .small) {
            onTapManage()
        }
        .accessibilityIdentifier(TestTags.balanceManageCoins)
    }

    @ViewBuilder private var statusView: some View {
        if !viewModel.isReachable {
            ThemeImage("globe_error", size: .iconSize20, colorStyle: .red)
                .accessibilityElement()
                .accessibilityLabel("alert.no_internet".localized)
                .accessibilityIdentifier(TestTags.balanceNoInternet)
        } else if viewModel.totalItem.state == .syncing {
            ProgressView(value: 0.6)
                .progressViewStyle(DeterminiteSpinnerStyle())
                .frame(size: .iconSize20)
                .spinning()
                .accessibilityIdentifier(TestTags.balanceSyncIndicator)
        }
    }

    private func topView(account: Account) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            AmountText(
                title: primaryValue,
                subtitle: secondaryValue,
                identifier: TestTags.balanceTotal,
                subtitleIdentifier: TestTags.balanceConverted,
                onTapTitle: {
                    viewModel.onTapAmount()
                    HapticGenerator.instance.notification(.feedback(.soft))
                },
                onTapSubtitle: {
                    viewModel.onTapConvertedAmount()
                    HapticGenerator.instance.notification(.feedback(.soft))
                },
                subtitleTrailing: { statusView }
            )

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
                .padding(.bottom, .margin24)
                .padding(.horizontal, .margin16)
            }
        }
        .padding(.bottom, .margin8)
    }

    private func emptyView(account: Account) -> some View {
        ThemeView {
            VStack(spacing: 0) {
                topView(account: account)

                PlaceholderViewNew(icon: "wallet_in", subtitle: "balance.no_tokens".localized) {
                    ThemeButton(text: "button.add".localized, icon: "plus", style: .secondary, mode: .transparent, size: .small) {
                        onTapManage()
                    }
                    .accessibilityIdentifier(TestTags.balanceManageCoins)
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
            text: viewModel.totalItem.convertedValue.flatMap { $0.formattedWith(rounding: viewModel.amountRounding) }.map { "≈\($0)" } ?? String.placeholder,
            dimmed: false
        )
    }
}

/// Owns the floating button's visibility, so it lives and resets with the list: a list built after the empty state
/// or without an account starts undetermined, while returning from a pushed page or another tab keeps it.
private struct FloatingButtonListView<Content: View, FloatingButton: View>: View {
    let isContentReady: Bool
    @ViewBuilder let content: () -> Content
    @ViewBuilder let button: () -> FloatingButton

    /// `nil` until the list's geometry decides it; drawn as hidden
    @State private var isButtonVisible: Bool?

    var body: some View {
        content()
            .floatingButtonVisibility($isButtonVisible, isContentReady: isContentReady)
            .overlay(alignment: .bottom) {
                ZStack {
                    if isButtonVisible == true {
                        button()
                            .padding(.bottom, .margin16)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: isButtonVisible)
            }
    }
}

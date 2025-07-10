import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModelNew
    @StateObject var accountWarningViewModel = AccountWarningViewModel(canIgnore: true)

    @Binding var path: NavigationPath

    @State private var sortTypePresented = false

    var body: some View {
        ThemeView(isRoot: true) {
            if viewModel.account != nil {
                ScrollViewReader { proxy in
                    ThemeList(bottomSpacing: .margin16) {
                        topView()
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)

                        AccountWarningView(viewModel: accountWarningViewModel)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .padding(.horizontal, .margin16)
                            .padding(.bottom, .margin16)

                        Section {
                            itemsView()
                        } header: {
                            headerView()
                        }
                    }
                    .animation(.default, value: viewModel.items)
                    .animation(.default, value: accountWarningViewModel.item)
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .onChange(of: viewModel.sortType) { _ in withAnimation { proxy.scrollTo(THEME_LIST_TOP_VIEW_ID) } }
                }
            } else {
                PlaceholderViewNew(image: Image("add_to_wallet_48"), layoutType: .bottom) {
                    VStack(spacing: .margin16) {
                        Button(action: {
                            Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                CreateAccountView(isPresented: isPresented)
                            } onPresent: {
                                stat(page: .balance, event: .open(page: .newWallet))
                            }
                        }) {
                            Text("onboarding.balance.create".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .yellow))

                        Button(action: {
                            Coordinator.shared.presentAfterAcceptTerms { isPresented in
                                RestoreTypeView(type: .wallet, isPresented: isPresented)
                            } onPresent: {
                                stat(page: .balance, event: .open(page: .importWallet))
                            }
                        }) {
                            Text("onboarding.balance.import".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .gray))

                        Button(action: {
                            Coordinator.shared.present { isPresented in
                                WatchView(isPresented: isPresented)
                            }
                            stat(page: .balance, event: .open(page: .watchWallet))
                        }) {
                            Text("onboarding.balance.watch".localized)
                        }
                        .buttonStyle(PrimaryButtonStyle(style: .transparent))
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
        .alert(
            isPresented: $sortTypePresented,
            title: "balance.sort.header".localized,
            viewItems: WalletModule.SortType.allCases.map { .init(text: $0.title, selected: viewModel.sortType == $0) },
            onTap: { index in
                guard let index else {
                    return
                }

                viewModel.sortType = WalletModule.SortType.allCases[index]
            }
        )
    }

    @ViewBuilder private func topView() -> some View {
        VStack(spacing: .margin24) {
            VStack(spacing: 0) {
                let (primaryText, primaryDimmed) = primaryValue
                Text(primaryText)
                    .textTitle2R(color: primaryDimmed ? .themeGray : .themeLeah)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        viewModel.onTapAmount()
                        HapticGenerator.instance.notification(.feedback(.soft))
                    }

                let (secondaryText, secondaryDimmed) = secondaryValue
                Text(secondaryText)
                    .textBody(color: secondaryDimmed ? .themeGray50 : .themeGray)
                    .multilineTextAlignment(.center)
                    .onTapGesture {
                        viewModel.onTapConvertedAmount()
                        HapticGenerator.instance.notification(.feedback(.soft))
                    }
            }
            .frame(maxWidth: .infinity)

            if !viewModel.buttonHidden, let account = viewModel.account, !account.watchAccount {
                let buttons = viewModel.buttons

                LazyVGrid(columns: buttons.map { _ in GridItem(.flexible(), alignment: .top) }, spacing: .margin16) {
                    ForEach(buttons, id: \.self) { button in
                        buttonView(button: button)
                    }
                }
                .padding(.top, .margin4)
            }
        }
        .padding(.vertical, .margin24)
        .padding(.horizontal, .margin16)
    }

    @ViewBuilder private func itemsView() -> some View {
        ForEach(viewModel.items) { item in
            VStack(spacing: 0) {
                if viewModel.items.first?.id == item.id {
                    HorizontalDivider()
                }

                WalletListItemView(item: item, balancePrimaryValue: viewModel.balancePrimaryValue, balanceHidden: viewModel.balanceHidden, subtitleMode: .price) {
                    path.append(item.wallet)
                } failedAction: {
                    Coordinator.shared.presentBalanceError(wallet: item.wallet, state: item.state)
                }
                .swipeActions {
                    Button {
                        viewModel.onDisable(wallet: item.wallet)
                    } label: {
                        Image("circle_minus_shifted_24").renderingMode(.template)
                    }
                    .tint(.themeGray)
                }

                HorizontalDivider()
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    @ViewBuilder private func headerView() -> some View {
        HStack(spacing: .margin8) {
            Button(action: {
                sortTypePresented = true
            }) {
                Text(viewModel.sortType.title)
            }
            .buttonStyle(SecondaryButtonStyle(style: .default, rightAccessory: .dropDown))

            Button(action: {
                if let account = viewModel.account {
                    Coordinator.shared.present { _ in
                        ManageWalletsView(account: account).ignoresSafeArea()
                    }
                    stat(page: .balance, event: .open(page: .coinManager))
                }
            }) {
                Image("manage_2_20").renderingMode(.template)
            }
            .buttonStyle(SecondaryCircleButtonStyle(style: .default))

            Spacer()
        }
        .padding(.horizontal, .margin16)
        .frame(maxWidth: .infinity)
        .frame(height: .heightCell48)
        .listRowInsets(EdgeInsets())
        .background(Color.themeLawrence)
    }

    @ViewBuilder private func buttonView(button: WalletButton) -> some View {
        VStack(spacing: .margin8) {
            Button(action: {
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
            }) {
                Image(button.icon).renderingMode(.template)
            }
            .buttonStyle(PrimaryCircleButtonStyle(style: button.accent ? .yellow : .gray))

            Text(button.title).textSubhead1()
        }
    }

    private var primaryValue: (String, Bool) {
        if viewModel.balanceHidden {
            return (BalanceHiddenManager.placeholder, false)
        }

        return (
            ValueFormatter.instance.formatShort(currencyValue: viewModel.totalItem.currencyValue) ?? String.placeholder,
            viewModel.totalItem.expired
        )
    }

    private var secondaryValue: (String, Bool) {
        if viewModel.balanceHidden {
            return (BalanceHiddenManager.placeholder, false)
        }

        return (
            viewModel.totalItem.convertedValue.flatMap { $0.formattedShort() }.map { "≈ \($0)" } ?? String.placeholder,
            viewModel.totalItem.convertedValueExpired
        )
    }
}

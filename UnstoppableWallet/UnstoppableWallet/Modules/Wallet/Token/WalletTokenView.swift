import SwiftUI

struct WalletTokenView<AdditionalContent: View>: View {
    @StateObject var viewModel: WalletTokenViewModelNew
    @StateObject var transactionsViewModel: TransactionsViewModelNew

    private let additionalContent: () -> AdditionalContent

    init(wallet: Wallet, @ViewBuilder additionalContent: @escaping () -> AdditionalContent = { EmptyView() }) {
        _viewModel = StateObject(wrappedValue: WalletTokenViewModelNew(wallet: wallet))
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModelNew(transactionFilter: .init(token: wallet.token)))
        self.additionalContent = additionalContent
    }

    var body: some View {
        ThemeView {
            ThemeList(bottomSpacing: .margin16) {
                topView()
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)

                TransactionsView(viewModel: transactionsViewModel, statPage: .tokenPage)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
    }

    @ViewBuilder private func topView() -> some View {
        VStack(spacing: .margin24) {
            VStack(spacing: 6) {
                BalanceCoinIconView(coin: viewModel.wallet.coin, state: viewModel.state, placeholderImage: viewModel.wallet.token.placeholderImageName) {
                    Coordinator.shared.presentBalanceError(wallet: viewModel.wallet, state: viewModel.state)
                }

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
            }

            let buttons = viewModel.buttons

            LazyVGrid(columns: buttons.map { _ in GridItem(.flexible(), alignment: .top) }, spacing: .margin16) {
                ForEach(buttons, id: \.self) { button in
                    buttonView(button: button)
                }
            }

            additionalContent()
        }
        .padding(EdgeInsets(top: 10, leading: .margin16, bottom: .margin12, trailing: .margin16))
    }

    @ViewBuilder private func buttonView(button: WalletButton) -> some View {
        VStack(spacing: .margin8) {
            Button(action: {
                switch button {
                case .send:
                    Coordinator.shared.present { isPresented in
                        ThemeNavigationStack {
                            SendAddressView(wallet: viewModel.wallet, isPresented: isPresented)
                        }
                    }
                    stat(page: .tokenPage, event: .openSend(token: viewModel.wallet.token))
                case .receive, .address: viewModel.onTapReceive()
                case .swap:
                    Coordinator.shared.present { _ in
                        MultiSwapView(token: viewModel.wallet.token)
                    }
                    stat(page: .tokenPage, event: .open(page: .swap))
                case .chart: Coordinator.shared.presentCoinPage(coin: viewModel.wallet.coin, page: .tokenPage)
                default: ()
                }
            }) {
                Image(button.icon).renderingMode(.template)
            }
            .buttonStyle(PrimaryCircleButtonStyle(style: button.accent ? .yellow : .gray))
            .disabled(button == .chart && viewModel.priceItem == nil)

            Text(button.title).textSubhead1()
        }
    }

    private var primaryValue: (String, Bool) {
        if viewModel.balanceHidden {
            return (BalanceHiddenManager.placeholder, false)
        }

        if let formatted = ValueFormatter.instance.formatFull(value: viewModel.balanceData.total, decimalCount: viewModel.wallet.decimals, symbol: viewModel.wallet.coin.code) {
            return (formatted, viewModel.state != .synced)
        }

        return ("----", false)
    }

    private var secondaryValue: (String, Bool) {
        switch viewModel.state {
        case let .syncing(progress, lastBlockDate):
            var text = ""
            if let progress {
                text = "balance.syncing_percent".localized("\(progress)%")
            } else {
                text = "balance.syncing".localized
            }

            if let syncedUntil = lastBlockDate.map({ DateHelper.instance.formatSyncedThroughDate(from: $0) }) {
                text += " - " + "balance.synced_through".localized(syncedUntil)
            }

            return (text: text, dimmed: false)
        case let .customSyncing(main, secondary, _):
            let text = [main, secondary].compactMap { $0 }.joined(separator: " - ")
            return (text: text, dimmed: false)
        case .stopped:
            return (text: "balance.stopped".localized, dimmed: false)
        default: ()
            if viewModel.balanceHidden {
                return (BalanceHiddenManager.placeholder, false)
            }

            guard let priceItem = viewModel.priceItem else {
                return (text: "----", dimmed: true)
            }

            let price = priceItem.price
            let currencyValue = CurrencyValue(currency: price.currency, value: viewModel.balanceData.total * price.value)

            if let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
                return (formatted, viewModel.state != .synced || priceItem.expired)
            }

            return ("----", false)
        }
    }
}

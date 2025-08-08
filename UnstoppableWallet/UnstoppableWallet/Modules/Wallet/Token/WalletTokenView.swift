import SwiftUI

struct WalletTokenView<AdditionalContent: View>: View {
    @StateObject var viewModel: WalletTokenViewModel
    @StateObject var transactionsViewModel: TransactionsViewModel

    private let additionalContent: () -> AdditionalContent

    init(wallet: Wallet, @ViewBuilder additionalContent: @escaping () -> AdditionalContent = { EmptyView() }) {
        _viewModel = StateObject(wrappedValue: WalletTokenViewModel(wallet: wallet))
        _transactionsViewModel = StateObject(wrappedValue: TransactionsViewModel(transactionFilter: .init(token: wallet.token)))
        self.additionalContent = additionalContent
    }

    var body: some View {
        ThemeView(background: .themeLawrence) {
            ThemeList(bottomSpacing: .margin16) {
                topView()
                    .listRowBackground(Color.themeTyler)
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
        VStack(alignment: .leading, spacing: .margin24) {
            VStack(alignment: .leading, spacing: 0) {
                BalanceCoinIconView(coin: viewModel.wallet.coin, state: viewModel.state, placeholderImage: viewModel.wallet.token.placeholderImageName) {
                    Coordinator.shared.presentBalanceError(wallet: viewModel.wallet, state: viewModel.state)
                }

                ThemeText(primaryValue, style: .title2)
                    .onTapGesture {
                        viewModel.onTapAmount()
                        HapticGenerator.instance.notification(.feedback(.soft))
                    }

                ThemeText(secondaryValue, style: .body, colorStyle: .secondary)
            }

            let buttons = viewModel.buttons

            HStack(spacing: 0) {
                ForEach(buttons, id: \.self) { button in
                    buttonView(button: button)

                    if button != buttons.last {
                        Spacer()
                    }
                }
            }

            additionalContent()
        }
        .padding(.vertical, .margin24)
        .padding(.horizontal, .margin16)
    }

    @ViewBuilder private func buttonView(button: WalletButton) -> some View {
        WalletButtonView(icon: button.icon, title: button.title, accent: button.accent) {
            switch button {
            case .send:
                Coordinator.shared.present { isPresented in
                    ThemeNavigationStack {
                        SendAddressView(wallet: viewModel.wallet, isPresented: isPresented)
                    }
                }
                stat(page: .tokenPage, event: .openSend(token: viewModel.wallet.token))
            case .receive: viewModel.onTapReceive()
            case .swap:
                Coordinator.shared.present { _ in
                    MultiSwapView(token: viewModel.wallet.token)
                }
                stat(page: .tokenPage, event: .open(page: .swap))
            case .chart: Coordinator.shared.presentCoinPage(coin: viewModel.wallet.coin, page: .tokenPage)
            default: ()
            }
        }
        .disabled(button == .chart && viewModel.priceItem == nil)
    }

    private var primaryValue: CustomStringConvertible {
        if viewModel.balanceHidden {
            return BalanceHiddenManager.placeholder
        }

        if let formatted = ValueFormatter.instance.formatFull(value: viewModel.balanceData.total, decimalCount: viewModel.wallet.decimals, symbol: viewModel.wallet.coin.code) {
            return ComponentText(text: formatted, dimmed: viewModel.state != .synced)
        }

        return "----"
    }

    private var secondaryValue: CustomStringConvertible {
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

            return text
        case let .customSyncing(main, secondary, _):
            return [main, secondary].compactMap { $0 }.joined(separator: " - ")
        case .stopped:
            return "balance.stopped".localized
        default: ()
            if viewModel.balanceHidden {
                return BalanceHiddenManager.placeholder
            }

            guard let priceItem = viewModel.priceItem else {
                return ComponentText(text: "----", dimmed: true)
            }

            let price = priceItem.price
            let currencyValue = CurrencyValue(currency: price.currency, value: viewModel.balanceData.total * price.value)

            if let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
                return ComponentText(text: formatted, dimmed: viewModel.state != .synced || priceItem.expired)
            }

            return "----"
        }
    }
}

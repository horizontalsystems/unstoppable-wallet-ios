import SwiftUI

struct WalletTokenTopView: View {
    @ObservedObject var viewModel: WalletTokenViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: .margin24) {
            VStack(alignment: .leading, spacing: 0) {
                ThemeText(primaryValue, style: .title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.onTapAmount()
                        HapticGenerator.instance.notification(.feedback(.soft))
                    }

                ThemeText(secondaryValue, style: .body, colorStyle: .secondary)
            }

            if !viewModel.wallet.account.watchAccount {
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
            } else {
                VStack(spacing: 0) {
                    Button(action: {
                        viewModel.onTapReceive()
                    }) {
                        WatchAddressView(wallet: viewModel.wallet)
                    }

                    if case .moneroWatchAccount = viewModel.wallet.account.type {
                        AlertCardView(
                            title: "watch_address.monero_warning.title".localized,
                            text: "watch_address.monero_warning.description".localized
                        )
                        .padding(.vertical, .margin16)
                    }
                }
            }
        }
        .padding(.top, .margin24)
        .padding(.horizontal, .margin16)
        .background(Color.themeTyler)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets())
        .listRowSeparator(.hidden)
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

        var colorStyle: ColorStyle = .primary
        var dimmed = false
        switch viewModel.state {
        case .synced:
            ()
        case .connecting, .syncing, .customSyncing:
            dimmed = true
        case .notSynced, .stopped:
            colorStyle = .secondary
        }

        if let formatted = ValueFormatter.instance.formatFull(value: viewModel.balanceData.total, decimalCount: viewModel.wallet.decimals, symbol: viewModel.wallet.coin.code) {
            return ComponentText(text: formatted, colorStyle: colorStyle, dimmed: dimmed)
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
                return " "
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

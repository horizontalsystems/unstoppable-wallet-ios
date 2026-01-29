import SwiftUI

struct WalletTokenTopView<Content: View>: View {
    @ObservedObject var viewModel: WalletTokenViewModel
    let content: () -> Content

    init(
        viewModel: WalletTokenViewModel,
        @ViewBuilder content: @escaping () -> Content = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
            .padding(.horizontal, 16)

            VStack(spacing: 0) {
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
                    .padding(.bottom, 24)
                    .padding(.horizontal, 16)
                } else if let address = viewModel.wallet.account.type.watchAddress {
                    Cell(
                        middle: {
                            MiddleTextIcon(text: "balance.token.receive_address".localized)
                        },
                        right: {
                            RightTextIcon(text: address.shortened, icon: "arrow_b_right")
                        },
                        action: {
                            viewModel.onTapReceive()
                        }
                    )
                }

                content()
            }
        }
        .padding(.top, 24)
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
                    SendAddressViewWrapper(wallet: viewModel.wallet, isPresented: isPresented)
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
            if viewModel.isReachable {
                colorStyle = .secondary
            }
        }

        if let formatted = ValueFormatter.instance.formatFull(value: viewModel.balanceData.total, decimalCount: viewModel.wallet.decimals, symbol: viewModel.wallet.coin.code) {
            return ComponentText(text: formatted, colorStyle: colorStyle, dimmed: dimmed)
        }

        return "----"
    }

    private var secondaryValue: CustomStringConvertible {
        switch viewModel.state {
        case let .syncing(_, remaining, _):
            var text = ""
            if let remaining {
                text = "balance.remaining".localized(remaining.description)
            } else {
                text = "balance.syncing".localized
            }

//            if let syncedUntil = lastBlockDate.map({ DateHelper.instance.formatSyncedThroughDate(from: $0) }) {
//                text += " - " + "balance.synced_through".localized(syncedUntil)
//            }

            return ComponentText(text: text, dimmed: true)
        case let .customSyncing(main, secondary, _):
            return [main, secondary].compactMap { $0 }.joined(separator: " - ")
        case .stopped:
            return "balance.stopped".localized
        default: ()
            if viewModel.balanceHidden {
                return " "
            }

            if let caution = viewModel.caution {
                return ComponentText(text: caution.text, colorStyle: caution.type.colorStyle)
            }

            guard let priceItem = viewModel.priceItem else {
                return ComponentText(text: "----", dimmed: true)
            }

            let price = priceItem.price
            let currencyValue = CurrencyValue(currency: price.currency, value: viewModel.balanceData.total * price.value)

            if let formatted = ValueFormatter.instance.formatFull(currencyValue: currencyValue) {
                return ComponentText(text: formatted, dimmed: priceItem.expired)
            }

            return "----"
        }
    }
}

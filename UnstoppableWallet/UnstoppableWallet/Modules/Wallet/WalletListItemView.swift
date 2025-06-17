import SwiftUI

struct WalletListItemView: View, Equatable {
    let item: WalletListViewModel.Item
    let balancePrimaryValue: BalancePrimaryValue
    let balanceHidden: Bool
    let subtitleMode: SubtitleMode
    let action: () -> Void
    let failedAction: () -> Void

    var body: some View {
        ClickableRow(padding: EdgeInsets(top: .margin12, leading: 10, bottom: .margin12, trailing: .margin16), action: action) {
            HStack(spacing: 10) {
                BalanceCoinIconView(coin: item.wallet.coin, state: item.state, placeholderImage: item.wallet.token.placeholderImageName) {
                    failedAction()
                }

                VStack(spacing: 1) {
                    HStack(spacing: .margin8) {
                        Text(item.wallet.coin.code)
                            .textBody()
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if let badge = item.wallet.badge {
                            BadgeViewNew(text: badge)
                        }

                        Spacer()

                        let (primaryText, primaryDimmed) = primaryValue
                        Text(primaryText)
                            .textBody(color: primaryDimmed ? .themeGray : .themeLeah)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    bottomView()
                }
            }
        }
    }

    @ViewBuilder private func bottomView() -> some View {
        switch item.state {
        case let .syncing(progress, lastBlockDate):
            HStack(spacing: .margin8) {
                bottomText(text: progress.map { "balance.syncing_percent".localized("\($0)%") } ?? "balance.syncing".localized)
                Spacer()

                if let lastBlockDate {
                    bottomText(text: "balance.synced_through".localized(DateHelper.instance.formatSyncedThroughDate(from: lastBlockDate)))
                }
            }
        case let .customSyncing(main, secondary, _):
            HStack(spacing: .margin8) {
                bottomText(text: main)
                Spacer()

                if let secondary {
                    bottomText(text: secondary)
                }
            }
        case .stopped:
            bottomText(text: "balance.stopped".localized)
        default:
            HStack(spacing: .margin8) {
                switch subtitleMode {
                case .price:
                    if let priceItem = item.priceItem {
                        HStack(spacing: .margin4) {
                            bottomText(
                                text: ValueFormatter.instance.formatFull(currencyValue: priceItem.price) ?? String.placeholder,
                                dimmed: priceItem.expired
                            )

                            if let diff = priceItem.diff {
                                DiffText(diff, expired: priceItem.expired)
                            }
                        }
                    } else {
                        bottomText(text: "n/a".localized)
                    }
                case .coinName:
                    bottomText(text: item.wallet.coin.name)
                }

                Spacer()

                let (secondaryText, secondaryDimmed) = secondaryValue
                bottomText(text: secondaryText, dimmed: secondaryDimmed)
            }
        }
    }

    @ViewBuilder private func bottomText(text: String, dimmed: Bool = false) -> some View {
        Text(text)
            .textSubhead2(color: dimmed ? .themeGray50 : .themeGray)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    private var primaryValue: (String, Bool) {
        if balanceHidden {
            return (BalanceHiddenManager.placeholder, false)
        }

        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.total, decimalCount: item.wallet.decimals, state: item.state)
        case .currency: return currencyValue(value: item.balanceData.total, state: item.state, priceItem: item.priceItem)
        }
    }

    private var secondaryValue: (String, Bool) {
        if balanceHidden {
            return (BalanceHiddenManager.placeholder, false)
        }

        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.total, state: item.state, priceItem: item.priceItem)
        case .currency: return coinValue(value: item.balanceData.total, decimalCount: item.wallet.decimals, state: item.state)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, state: AdapterState, expanded _: Bool = false) -> (text: String, dimmed: Bool) {
        (
            text: ValueFormatter.instance.formatShort(value: value, decimalCount: decimalCount, symbol: symbol) ?? String.placeholder,
            dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?, expanded _: Bool = false) -> (text: String, dimmed: Bool) {
        guard let priceItem else {
            return (text: String.placeholder, dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return (
            text: ValueFormatter.instance.formatShort(currencyValue: currencyValue) ?? String.placeholder,
            dimmed: state != .synced || priceItem.expired
        )
    }

    static func == (lhs: WalletListItemView, rhs: WalletListItemView) -> Bool {
        lhs.item == rhs.item && lhs.balancePrimaryValue == rhs.balancePrimaryValue && lhs.balanceHidden == rhs.balanceHidden
    }

    enum SubtitleMode {
        case price
        case coinName
    }
}

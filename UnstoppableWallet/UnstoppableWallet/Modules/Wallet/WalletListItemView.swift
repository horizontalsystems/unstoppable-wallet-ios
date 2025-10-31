import SwiftUI

struct WalletListItemView: View, Equatable {
    let item: WalletListViewModel.Item
    let balancePrimaryValue: BalancePrimaryValue
    let balanceHidden: Bool
    let amountRounding: Bool
    let subtitleMode: SubtitleMode
    let isReachable: Bool
    let action: () -> Void
    let failedAction: () -> Void

    var body: some View {
        Cell(
            left: {
                BalanceCoinIconView(coin: item.wallet.coin, state: item.state, isReachable: isReachable, placeholderImage: item.wallet.token.placeholderImageName) {
                    failedAction()
                }
            },
            middle: {
                MultiText(
                    title: item.wallet.coin.code,
                    badge: item.wallet.badge,
                    subtitle: subtitle,
                    subtitle2: subtitle2
                )
            },
            right: {
                RightMultiText(
                    title: primaryValue,
                    subtitle: secondary
                )
            },
            action: action
        )
    }

    private var subtitle: CustomStringConvertible {
        if !isReachable {
            return itemSubtitle
        }

        switch item.state {
        case let .syncing(progress, remaining, _):
            return remaining.map { "balance.remaining".localized("\($0)") } ?? "balance.syncing".localized
        case let .customSyncing(main, _, _):
            return main
        case .connecting:
            return "balance.connecting".localized
        case .stopped:
            return "balance.stopped".localized
        case .notSynced:
            return "balance_error.sync_error".localized
        case .synced:
            return itemSubtitle
        }
    }

    private var itemSubtitle: CustomStringConvertible {
        switch subtitleMode {
        case .price:
            if let priceItem = item.priceItem {
                return ComponentText(text: ValueFormatter.instance.formatFull(currencyValue: priceItem.price) ?? String.placeholder, dimmed: priceItem.expired)
            } else {
                return "n/a".localized
            }
        case .coinName:
            return item.wallet.coin.name
        }
    }

    private var subtitle2: CustomStringConvertible? {
        if !isReachable {
            return itemSubtitle2
        }

        switch item.state {
        case .synced:
            return itemSubtitle2
        default:
            return nil
        }
    }

    private var itemSubtitle2: CustomStringConvertible? {
        switch subtitleMode {
        case .price:
            return item.priceItem.map { Diff.text(diff: $0.diff, expired: $0.expired) }
        default:
            return nil
        }
    }

    private var secondary: CustomStringConvertible? {
        if !isReachable {
            return secondaryValue
        }

        switch item.state {
        case .syncing:
//            return lastBlockDate.map { "balance.synced_through".localized(DateHelper.instance.formatSyncedThroughDate(from: $0)) } ?? secondaryValue
            return secondaryValue
        case let .customSyncing(_, secondary, _):
            return secondary
        case .stopped:
            return nil
        default:
            return secondaryValue
        }
    }

    private var primaryValue: CustomStringConvertible {
        if balanceHidden {
            return BalanceHiddenManager.placeholder
        }

        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.total, decimalCount: item.wallet.decimals, state: item.state)
        case .currency: return currencyValue(value: item.balanceData.total, state: item.state, priceItem: item.priceItem)
        }
    }

    private var secondaryValue: CustomStringConvertible? {
        if balanceHidden {
            return nil
        }

        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.total, state: item.state, priceItem: item.priceItem)
        case .currency: return coinValue(value: item.balanceData.total, decimalCount: item.wallet.decimals, state: item.state)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, state: AdapterState, expanded _: Bool = false) -> CustomStringConvertible {
        ComponentText(
            text: ValueFormatter.instance.formatWith(rounding: amountRounding, value: value, decimalCount: decimalCount, symbol: symbol) ?? String.placeholder,
            dimmed: (state != .synced) && isReachable
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?, expanded _: Bool = false) -> CustomStringConvertible {
        guard let priceItem else {
            return ComponentText(text: String.placeholder, dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return ComponentText(
            text: ValueFormatter.instance.formatWith(rounding: amountRounding, currencyValue: currencyValue) ?? String.placeholder,
            dimmed: (state != .synced && isReachable) || priceItem.expired
        )
    }

    static func == (lhs: WalletListItemView, rhs: WalletListItemView) -> Bool {
        lhs.item == rhs.item &&
            lhs.balancePrimaryValue == rhs.balancePrimaryValue &&
            lhs.balanceHidden == rhs.balanceHidden &&
            lhs.amountRounding == rhs.amountRounding
    }

    enum SubtitleMode {
        case price
        case coinName
    }
}

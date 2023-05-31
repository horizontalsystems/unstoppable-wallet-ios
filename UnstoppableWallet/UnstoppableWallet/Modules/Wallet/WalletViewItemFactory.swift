import Foundation
import CurrencyKit
import MarketKit
import EvmKit

class WalletViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    init() {
    }

    private func topViewItem(balanceItem: IBalanceItem, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded: Bool) -> BalanceTopViewItem {
        let coin = balanceItem.item.coin
        let state = balanceItem.state

        return BalanceTopViewItem(
                isMainNet: balanceItem.isMainNet,
                iconUrlString: iconUrlString(coin: coin, state: state),
                placeholderIconName: balanceItem.item.wallet?.token.placeholderImageName ?? "placeholder_circle_32",
                coinCode: coin.code,
                blockchainBadge: balanceItem.item.wallet?.badge,
                syncSpinnerProgress: syncSpinnerProgress(state: state),
                indefiniteSearchCircle: indefiniteSearchCircle(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state),
                primaryValue: balanceHidden ? nil : primaryValue(balanceItem: balanceItem, balancePrimaryValue: balancePrimaryValue, expanded: expanded),
                secondaryInfo: secondaryInfo(balanceItem: balanceItem, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden, expanded: expanded)
        )
    }

    private func secondaryInfo(balanceItem: IBalanceItem, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded: Bool) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = balanceItem.state, expanded {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .customSyncing(main, secondary, _) = balanceItem.state, expanded {
            return .customSyncing(main: main, secondary: secondary)
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                    secondaryValue: balanceHidden ? nil : secondaryValue(balanceItem: balanceItem, balancePrimaryValue: balancePrimaryValue, expanded: expanded),
                    rateValue: rateValue(rateItem: balanceItem.priceItem),
                    diff: diff(rateItem: balanceItem.priceItem)
            ))
        }
    }

    private func lockedAmountViewItem(balanceItem: IBalanceItem, balanceHidden: Bool, expanded: Bool) -> BalanceLockedAmountViewItem? {
        guard balanceItem.balanceData.balanceLocked > 0, !balanceHidden, expanded else {
            return nil
        }

        return BalanceLockedAmountViewItem(
                coinValue: coinValue(value: balanceItem.balanceData.balanceLocked, decimalCount: balanceItem.item.decimals, state: balanceItem.state, expanded: true),
                currencyValue: currencyValue(value: balanceItem.balanceData.balanceLocked, state: balanceItem.state, priceItem: balanceItem.priceItem, expanded: true)
        )
    }

    private func iconUrlString(coin: Coin, state: AdapterState) -> String? {
        switch state {
        case .notSynced: return nil
        default: return coin.imageUrl
        }
    }

    private func syncSpinnerProgress(state: AdapterState) -> Int? {
        switch state {
        case let .syncing(progress, _):
            if let progress = progress {
                return max(minimumProgress, progress)
            } else {
                return infiniteProgress
            }
        case .customSyncing:
            return infiniteProgress
        default: return nil
        }
    }

    private func indefiniteSearchCircle(state: AdapterState) -> Bool {
        switch state {
        case .customSyncing: return true
        default: return false
        }
    }

    private func failedImageViewVisible(state: AdapterState) -> Bool {
        switch state {
        case .notSynced: return true
        default: return false
        }
    }

    private func rateValue(rateItem: WalletCoinPriceService.Item?) -> (text: String?, dimmed: Bool) {
        guard let rateItem = rateItem else {
            return (text: "n/a".localized, dimmed: true)
        }

        let formattedValue = ValueFormatter.instance.formatFull(currencyValue: rateItem.price)
        return (text: formattedValue, dimmed: rateItem.expired)
    }

    private func diff(rateItem: WalletCoinPriceService.Item?) -> (text: String, type: BalanceDiffType)? {
        guard let rateItem, let value = rateItem.diff else {
            return nil
        }

        guard let formattedValue = ValueFormatter.instance.format(percentValue: value, showSign: true) else {
            return nil
        }

        return (text: formattedValue, type: rateItem.expired ? .dimmed : (value < 0 ? .negative : .positive))
    }

    private func primaryValue(balanceItem: IBalanceItem, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(value: balanceItem.balanceData.balanceTotal, decimalCount: balanceItem.item.decimals, state: balanceItem.state, expanded: expanded)
        case .currency: return currencyValue(value: balanceItem.balanceData.balanceTotal, state: balanceItem.state, priceItem: balanceItem.priceItem, expanded: expanded)
        }
    }

    private func secondaryValue(balanceItem: IBalanceItem, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: balanceItem.balanceData.balanceTotal, state: balanceItem.state, priceItem: balanceItem.priceItem, expanded: expanded)
        case .currency: return coinValue(value: balanceItem.balanceData.balanceTotal, decimalCount: balanceItem.item.decimals, state: balanceItem.state, expanded: expanded)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, state: AdapterState, expanded: Bool) -> (text: String?, dimmed: Bool) {
        (
                text: expanded ? ValueFormatter.instance.formatFull(value: value, decimalCount: decimalCount) : ValueFormatter.instance.formatShort(value: value, decimalCount: decimalCount),
                dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?, expanded: Bool) -> (text: String?, dimmed: Bool) {
        guard let priceItem = priceItem else {
            return (text: "---", dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return (
                text: expanded ? ValueFormatter.instance.formatFull(currencyValue: currencyValue) : ValueFormatter.instance.formatShort(currencyValue: currencyValue),
                dimmed: state != .synced || priceItem.expired
        )
    }

}

extension WalletViewItemFactory {

    func viewItem(balanceItem: IBalanceItem, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded: Bool) -> BalanceViewItem {
        BalanceViewItem(
                item: balanceItem.item,
                topViewItem: topViewItem(balanceItem: balanceItem, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden, expanded: expanded),
                lockedAmountViewItem: lockedAmountViewItem(balanceItem: balanceItem, balanceHidden: balanceHidden, expanded: expanded),
                buttons: expanded ? balanceItem.buttons : nil
        )
    }

    func headerViewItem(totalItem: WalletModule.TotalItem, balanceHidden: Bool, watchAccount: Bool) -> WalletViewModel.HeaderViewItem {
        let amount = balanceHidden ? "*****" : ValueFormatter.instance.formatShort(currencyValue: totalItem.currencyValue)

        let convertedValue: String
        if balanceHidden {
            convertedValue = "*****"
        } else if let value = totalItem.convertedValue, let formattedValue = ValueFormatter.instance.formatShort(coinValue: value) {
            convertedValue = "≈ \(formattedValue)"
        } else {
            convertedValue = "---"
        }

        return WalletViewModel.HeaderViewItem(
                amount: amount,
                amountExpired: balanceHidden ? false : totalItem.expired,
                convertedValue: convertedValue,
                convertedValueExpired: balanceHidden ? false : totalItem.convertedValueExpired,
                watchAccount: watchAccount
        )
    }

}

import Foundation
import CurrencyKit
import MarketKit
import EvmKit

class WalletViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    init() {
    }

    private func topViewItem(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded: Bool) -> BalanceTopViewItem {
        let state = item.state

        return BalanceTopViewItem(
                isMainNet: item.isMainNet,
                iconUrlString: iconUrlString(coin: item.element.coin, state: state),
                placeholderIconName: item.element.wallet?.token.placeholderImageName ?? "placeholder_circle_32",
                name: item.element.name,
                blockchainBadge: item.element.wallet?.badge,
                syncSpinnerProgress: syncSpinnerProgress(state: state),
                indefiniteSearchCircle: indefiniteSearchCircle(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state),
                primaryValue: balanceHidden ? nil : primaryValue(item: item, balancePrimaryValue: balancePrimaryValue, expanded: expanded),
                secondaryInfo: secondaryInfo(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden, expanded: expanded)
        )
    }

    private func secondaryInfo(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded: Bool) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = item.state, expanded {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .customSyncing(main, secondary, _) = item.state, expanded {
            return .customSyncing(main: main, secondary: secondary)
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                    secondaryValue: balanceHidden ? nil : secondaryValue(item: item, balancePrimaryValue: balancePrimaryValue, expanded: expanded),
                    rateValue: rateValue(rateItem: item.priceItem),
                    diff: diff(rateItem: item.priceItem)
            ))
        }
    }

    private func lockedAmountViewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceLockedAmountViewItem? {
        guard item.balanceData.balanceLocked > 0, !balanceHidden, expanded else {
            return nil
        }

        return BalanceLockedAmountViewItem(
                coinValue: coinValue(value: item.balanceData.balanceLocked, decimalCount: item.element.decimals, state: item.state, expanded: true),
                currencyValue: currencyValue(value: item.balanceData.balanceLocked, state: item.state, priceItem: item.priceItem, expanded: true)
        )
    }

    private func iconUrlString(coin: Coin?, state: AdapterState) -> String? {
        switch state {
        case .notSynced: return nil
        default: return coin?.imageUrl
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

    private func primaryValue(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state, expanded: expanded)
        case .currency: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, expanded: expanded)
        }
    }

    private func secondaryValue(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, expanded: expanded)
        case .currency: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state, expanded: expanded)
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

    private func buttons(item: WalletService.Item) -> [WalletModule.Button: ButtonState]? {
        var buttons = [WalletModule.Button: ButtonState]()

        switch item.element {
        case .wallet(let wallet):
            if item.watchAccount {
                buttons[.address] = .enabled
            } else {
                let sendButtonState: ButtonState = item.state == .synced ? .enabled : .disabled

                buttons[.send] = sendButtonState
                buttons[.receive] = .enabled

                if wallet.token.swappable {
                    buttons[.swap] = sendButtonState
                }
            }
        case .cexAsset:
            buttons[.withdraw] = .enabled
            buttons[.deposit] = .enabled
        }

        buttons[.chart] = item.priceItem != nil ? .enabled : .disabled

        return buttons
    }

}

extension WalletViewItemFactory {

    func viewItem(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded: Bool) -> BalanceViewItem {
        BalanceViewItem(
                element: item.element,
                topViewItem: topViewItem(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden, expanded: expanded),
                lockedAmountViewItem: lockedAmountViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
                buttons: expanded ? buttons(item: item) : nil
        )
    }

    func headerViewItem(totalItem: WalletService.TotalItem, balanceHidden: Bool, watchAccount: Bool, cexAccount: Bool) -> WalletViewModel.HeaderViewItem {
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
                watchAccount: watchAccount,
                cexAccount: cexAccount
        )
    }

}

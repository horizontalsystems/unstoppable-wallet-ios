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
        let coin = item.wallet.coin
        let state = item.state

        return BalanceTopViewItem(
                isMainNet: item.isMainNet,
                iconUrlString: iconUrlString(wallet: item.wallet, state: state),
                placeholderIconName: item.wallet.token.placeholderImageName,
                coinCode: coin.code,
                blockchainBadge: item.wallet.badge,
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
                coinValue: coinValue(token: item.wallet.token, value: item.balanceData.balanceLocked, state: item.state, expanded: true),
                currencyValue: currencyValue(value: item.balanceData.balanceLocked, state: item.state, priceItem: item.priceItem, expanded: true)
        )
    }

    private func buttonsViewItem(item: WalletService.Item, watchAccount: Bool, expanded: Bool) -> BalanceButtonsViewItem? {
        guard expanded else {
            return nil
        }

        let sendButtonsState: ButtonState = watchAccount ? .hidden : (item.state == .synced ? .enabled : .disabled)

        return BalanceButtonsViewItem(
                sendButtonState: sendButtonsState,
                receiveButtonState: watchAccount ? .hidden : .enabled,
                addressButtonState: watchAccount ? .enabled : .hidden,
                swapButtonState: watchAccount ? .hidden : (item.wallet.token.swappable ? sendButtonsState : .hidden),
                chartButtonState: item.priceItem != nil ? .enabled : .disabled
        )
    }

    private func iconUrlString(wallet: Wallet, state: AdapterState) -> String? {
        switch state {
        case .notSynced: return nil
        default: return wallet.coin.imageUrl
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
        guard let rateItem = rateItem else {
            return nil
        }

        let value = rateItem.diff

        guard let formattedValue = ValueFormatter.instance.format(percentValue: value, showSign: true) else {
            return nil
        }

        return (text: formattedValue, type: rateItem.expired ? .dimmed : (value < 0 ? .negative : .positive))
    }

    private func primaryValue(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(token: item.wallet.token, value: item.balanceData.balanceTotal, state: item.state, expanded: expanded)
        case .currency: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, expanded: expanded)
        }
    }

    private func secondaryValue(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, expanded: expanded)
        case .currency: return coinValue(token: item.wallet.token, value: item.balanceData.balanceTotal, state: item.state, expanded: expanded)
        }
    }

    private func coinValue(token: Token, value: Decimal, state: AdapterState, expanded: Bool) -> (text: String?, dimmed: Bool) {
        (
                text: expanded ? ValueFormatter.instance.formatFull(value: value, decimalCount: token.decimals) : ValueFormatter.instance.formatShort(value: value, decimalCount: token.decimals),
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

    func viewItem(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, watchAccount: Bool, expanded: Bool) -> BalanceViewItem {
        BalanceViewItem(
                wallet: item.wallet,
                topViewItem: topViewItem(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden, expanded: expanded),
                lockedAmountViewItem: lockedAmountViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
                buttonsViewItem: buttonsViewItem(item: item, watchAccount: watchAccount, expanded: expanded)
        )
    }

    func headerViewItem(totalItem: WalletService.TotalItem, balanceHidden: Bool, watchAccount: Bool) -> WalletViewModel.HeaderViewItem {
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

import Foundation
import XRatesKit
import CurrencyKit
import CoinKit

class WalletViewItemFactory {
    private let minimumProgress = 10

    init() {
    }

    private func topViewItem(item: WalletService.Item) -> BalanceTopViewItem {
        let coin = item.wallet.coin
        let state = item.state
        let rateItem = item.rateItem

        return BalanceTopViewItem(
                iconCoinType: iconCoinType(coin: coin, state: state),
                coinTitle: coin.title,
                blockchainBadge: badge(wallet: item.wallet),
                rateValue: rateValue(rateItem: rateItem),
                diff: diff(rateItem: rateItem),
                syncSpinnerProgress: syncSpinnerProgress(state: state),
                indefiniteSearchCircle: indefiniteSearchCircle(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state)
        )
    }

    private func badge(wallet: Wallet) -> String? {
        switch wallet.coin.type {
        case .bitcoin, .litecoin:
            return wallet.configuredCoin.settings.derivation?.rawValue.uppercased()
        case .bitcoinCash:
            return wallet.configuredCoin.settings.bitcoinCashCoinType?.rawValue.uppercased()
        default:
            return wallet.coin.type.blockchainType
        }
    }

    private func amountViewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceAmountViewItem? {
        guard !balanceHidden else {
            return nil
        }

        if let state = item.state, let balance = item.balanceTotal {
            if case let .syncing(progress, lastBlockDate) = state, !expanded {
                if let lastBlockDate = lastBlockDate {
                    return .syncing(progress: progress, syncedUntil: DateHelper.instance.formatSyncedThroughDate(from: lastBlockDate))
                } else {
                    return .syncing(progress: nil, syncedUntil: nil)
                }
            } else if case let .searchingTxs(count) = state, !expanded {
                return .searchingTx(count: count)
            } else {
                return .amount(
                        coinValue: coinValue(coin: item.wallet.coin, value: balance, state: state),
                        currencyValue: currencyValue(value: balance, state: state, rateItem: item.rateItem)
                )
            }
        } else {
            return .syncing(progress: nil, syncedUntil: nil)
        }
    }

    private func lockedAmountViewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceLockedAmountViewItem? {
        guard let state = item.state, let balanceLocked = item.balanceLocked, !balanceHidden, expanded else {
            return nil
        }

        return BalanceLockedAmountViewItem(
                lockedCoinValue: coinValue(coin: item.wallet.coin, value: balanceLocked, state: state),
                lockedCurrencyValue: currencyValue(value: balanceLocked, state: state, rateItem: item.rateItem)
        )
    }

    private func buttonsViewItem(item: WalletService.Item, expanded: Bool) -> BalanceButtonsViewItem? {
        guard expanded else {
            return nil
        }

        let sendButtonsState: ButtonState = item.state == .synced ? .enabled : .disabled

        return BalanceButtonsViewItem(
                receiveButtonState: item.state != nil ? .enabled : .disabled,
                sendButtonState: sendButtonsState,
                swapButtonState: item.wallet.coin.type.swappable ? sendButtonsState : .hidden
        )
    }

    private func iconCoinType(coin: Coin, state: AdapterState?) -> CoinType? {
        if let state = state, case .notSynced = state {
            return nil
        }
        return coin.type
    }

    private func syncSpinnerProgress(state: AdapterState?) -> Int? {
        if let state = state, case let .syncing(progress, _) = state {
            return max(minimumProgress, progress)
        }
        return nil
    }

    private func indefiniteSearchCircle(state: AdapterState?) -> Bool {
        if let state = state, case .searchingTxs(_) = state {
            return true
        }
        return false
    }

    private func failedImageViewVisible(state: AdapterState?) -> Bool {
        if let state = state, case .notSynced = state {
            return true
        }
        return false
    }

    private func rateValue(rateItem: WalletRateService.Item?) -> (text: String, dimmed: Bool)? {
        guard let rateItem = rateItem else {
            return nil
        }

        guard let formattedValue = ValueFormatter.instance.format(currencyValue: rateItem.rate, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) else {
            return nil
        }

        return (text: formattedValue, dimmed: rateItem.expired)
    }

    private func diff(rateItem: WalletRateService.Item?) -> (value: Decimal, dimmed: Bool)? {
        guard let rateItem = rateItem else {
            return nil
        }

        return (value: rateItem.diff24h, dimmed: rateItem.expired)
    }

    private func coinValue(coin: Coin, value: Decimal, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
                text: ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: value), fractionPolicy: .threshold(high: 0.01, low: 0)),
                dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, rateItem: WalletRateService.Item?) -> (text: String?, dimmed: Bool)? {
        guard let rateItem = rateItem else {
            return nil
        }

        let rate = rateItem.rate

        return (
                text: ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: rate.currency, value: value * rate.value), fractionPolicy: .threshold(high: 1000, low: 0.01)),
                dimmed: state != .synced || rateItem.expired
        )
    }

}

extension WalletViewItemFactory {

    func viewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceViewItem {
        BalanceViewItem(
                wallet: item.wallet,
                topViewItem: topViewItem(item: item),
                separatorVisible: !balanceHidden || expanded,
                amountViewItem: amountViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
                lockedAmountViewItem: lockedAmountViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
                buttonsViewItem: buttonsViewItem(item: item, expanded: expanded)
        )
    }

    func headerViewItem(totalItem: WalletService.TotalItem, balanceHidden: Bool) -> WalletViewModel.HeaderViewItem {
        let currencyValue = CurrencyValue(currency: totalItem.currency, value: totalItem.amount)
        let amount = balanceHidden ? "*****" : ValueFormatter.instance.format(currencyValue: currencyValue)

        return WalletViewModel.HeaderViewItem(
                amount: amount,
                amountExpired: balanceHidden ? false : totalItem.expired
        )
    }

}

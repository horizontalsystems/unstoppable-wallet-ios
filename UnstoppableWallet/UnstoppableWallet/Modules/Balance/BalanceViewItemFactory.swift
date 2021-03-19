import Foundation
import XRatesKit
import CurrencyKit
import CoinKit

class BalanceViewItemFactory {
    private let minimumProgress = 10

    init() {
    }

    private func topViewItem(item: BalanceItem, currency: Currency) -> BalanceTopViewItem {
        let coin = item.wallet.coin
        let state = item.state
        let latestRate = item.latestRate

        return BalanceTopViewItem(
                iconCoinType: iconCoinType(coin: coin, state: state),
                coinTitle: coin.title,
                blockchainBadge: coin.type.blockchainType,
                rateValue: rateValue(currency: currency, latestRate: latestRate),
                diff: diff(latestRate: latestRate),
                syncSpinnerProgress: syncSpinnerProgress(state: state),
                indefiniteSearchCircle: indefiniteSearchCircle(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state)
        )
    }

    private func amountViewItem(item: BalanceItem, currency: Currency, balanceHidden: Bool, expanded: Bool) -> BalanceAmountViewItem? {
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
                        currencyValue: currencyValue(currency: currency, value: balance, state: state, latestRate: item.latestRate)
                )
            }
        } else {
            return .syncing(progress: nil, syncedUntil: nil)
        }
    }

    private func lockedAmountViewItem(item: BalanceItem, currency: Currency, balanceHidden: Bool, expanded: Bool) -> BalanceLockedAmountViewItem? {
        guard let state = item.state, let balanceLocked = item.balanceLocked, !balanceHidden, expanded else {
            return nil
        }

        return BalanceLockedAmountViewItem(
                lockedCoinValue: coinValue(coin: item.wallet.coin, value: balanceLocked, state: state),
                lockedCurrencyValue: currencyValue(currency: currency, value: balanceLocked, state: state, latestRate: item.latestRate)
        )
    }

    private func buttonsViewItem(item: BalanceItem, expanded: Bool) -> BalanceButtonsViewItem? {
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

    private func rateValue(currency: Currency, latestRate: LatestRate?) -> (text: String, dimmed: Bool)? {
        guard let latestRate = latestRate else {
            return nil
        }

        let exchangeValue = CurrencyValue(currency: currency, value: latestRate.rate)

        guard let formattedValue = ValueFormatter.instance.format(currencyValue: exchangeValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) else {
            return nil
        }

        return (text: formattedValue, dimmed: latestRate.expired)
    }

    private func diff(latestRate: LatestRate?) -> (value: Decimal, dimmed: Bool)? {
        guard let latestRate = latestRate else {
            return nil
        }

        return (value: latestRate.rateDiff24h, dimmed: latestRate.expired)
    }

    private func coinValue(coin: Coin, value: Decimal, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
                text: ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: value), fractionPolicy: .threshold(high: 0.01, low: 0)),
                dimmed: state != .synced
        )
    }

    private func currencyValue(currency: Currency, value: Decimal, state: AdapterState, latestRate: LatestRate?) -> (text: String?, dimmed: Bool)? {
        latestRate.map { latestRate in
            (
                    text: ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: currency, value: value * latestRate.rate), fractionPolicy: .threshold(high: 1000, low: 0.01)),
                    dimmed: state != .synced || latestRate.expired
            )
        }
    }

}

extension BalanceViewItemFactory: IBalanceViewItemFactory {

    func viewItem(item: BalanceItem, currency: Currency, balanceHidden: Bool, expanded: Bool) -> BalanceViewItem {
        BalanceViewItem(
                wallet: item.wallet,
                topViewItem: topViewItem(item: item, currency: currency),
                separatorVisible: !balanceHidden || expanded,
                amountViewItem: amountViewItem(item: item, currency: currency, balanceHidden: balanceHidden, expanded: expanded),
                lockedAmountViewItem: lockedAmountViewItem(item: item, currency: currency, balanceHidden: balanceHidden, expanded: expanded),
                buttonsViewItem: buttonsViewItem(item: item, expanded: expanded)
        )
    }

    func headerViewItem(items: [BalanceItem], currency: Currency, sortingOnThreshold: Int) -> BalanceHeaderViewItem {
        var total: Decimal = 0
        var upToDate = true

        items.forEach { item in
            if let balanceTotal = item.balanceTotal, let latestRate = item.latestRate {
                total += balanceTotal * latestRate.rate

                if latestRate.expired {
                    upToDate = false
                }
            }

            if case .synced = item.state {
                // do nothing
            } else {
                upToDate = false
            }
        }

        let currencyValue = CurrencyValue(currency: currency, value: total)

        return BalanceHeaderViewItem(
                currencyValue: currencyValue,
                upToDate: upToDate,
                sortIsOn: items.count >= sortingOnThreshold
        )
    }

}

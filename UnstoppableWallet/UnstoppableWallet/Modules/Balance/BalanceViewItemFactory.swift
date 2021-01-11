import Foundation
import XRatesKit
import CurrencyKit

class BalanceViewItemFactory {
    private let minimumProgress = 10

    init() {
    }

    private func topViewItem(item: BalanceItem, currency: Currency) -> BalanceTopViewItem {
        let coin = item.wallet.coin
        let state = item.state
        let marketInfo = item.marketInfo

        return BalanceTopViewItem(
                coinIconCode: coinIconCode(coin: coin, state: state),
                coinTitle: coin.title,
                blockchainBadge: coin.type.blockchainType,
                rateValue: rateValue(currency: currency, marketInfo: marketInfo),
                diff: diff(marketInfo: marketInfo),
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
                        currencyValue: currencyValue(currency: currency, value: balance, state: state, marketInfo: item.marketInfo)
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
                lockedCurrencyValue: currencyValue(currency: currency, value: balanceLocked, state: state, marketInfo: item.marketInfo)
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

    private func coinIconCode(coin: Coin, state: AdapterState?) -> String? {
        if let state = state, case .notSynced = state {
            return nil
        }
        return coin.code
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

    private func rateValue(currency: Currency, marketInfo: MarketInfo?) -> (text: String, dimmed: Bool)? {
        guard let marketInfo = marketInfo else {
            return nil
        }

        let exchangeValue = CurrencyValue(currency: currency, value: marketInfo.rate)

        guard let formattedValue = ValueFormatter.instance.format(currencyValue: exchangeValue, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false) else {
            return nil
        }

        return (text: formattedValue, dimmed: marketInfo.expired)
    }

    private func diff(marketInfo: MarketInfo?) -> (value: Decimal, dimmed: Bool)? {
        guard let marketInfo = marketInfo else {
            return nil
        }

        return (value: marketInfo.rateDiff, dimmed: marketInfo.expired)
    }

    private func coinValue(coin: Coin, value: Decimal, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
                text: ValueFormatter.instance.format(coinValue: CoinValue(coin: coin, value: value), fractionPolicy: .threshold(high: 0.01, low: 0)),
                dimmed: state != .synced
        )
    }

    private func currencyValue(currency: Currency, value: Decimal, state: AdapterState, marketInfo: MarketInfo?) -> (text: String?, dimmed: Bool)? {
        marketInfo.map { marketInfo in
            (
                    text: ValueFormatter.instance.format(currencyValue: CurrencyValue(currency: currency, value: value * marketInfo.rate), fractionPolicy: .threshold(high: 1000, low: 0.01)),
                    dimmed: state != .synced || marketInfo.expired
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
            if let balanceTotal = item.balanceTotal, let marketInfo = item.marketInfo {
                total += balanceTotal * marketInfo.rate

                if marketInfo.expired {
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

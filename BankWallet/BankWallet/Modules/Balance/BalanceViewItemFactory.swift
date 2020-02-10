import Foundation
import XRatesKit
import CurrencyKit

class BalanceViewItemFactory {
    private let minimumProgress = 10
    private let blockedChartCoins: IBlockedChartCoins

    init(blockedChartCoins: IBlockedChartCoins) {
        self.blockedChartCoins = blockedChartCoins
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

        return (value: marketInfo.diff, dimmed: marketInfo.expired)
    }

    private func coinValue(state: AdapterState?, balance: Decimal?, coin: Coin, expanded: Bool) -> (text: String, dimmed: Bool)? {
        guard let state = state, let balance = balance else {
            return nil
        }

        if case .syncing = state, !expanded {
            return nil
        }

        let coinValue = CoinValue(coin: coin, value: balance)

        guard let formattedValue = ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) else {
            return nil
        }

        return (text: formattedValue, dimmed: state != .synced)
    }

    private func coinValueLocked(state: AdapterState?, balanceLocked: Decimal?, coin: Coin, expanded: Bool) -> (text: String, dimmed: Bool)? {
        guard let state = state, let balanceLocked = balanceLocked else {
            return nil
        }

        if !expanded {
            return nil
        }

        let coinValue = CoinValue(coin: coin, value: balanceLocked)

        guard let formattedValue = ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) else {
            return nil
        }

        return (text: formattedValue, dimmed: state != .synced)
    }

    private func currencyValue(state: AdapterState?, balance: Decimal?, currency: Currency, marketInfo: MarketInfo?, expanded: Bool) -> (text: String, dimmed: Bool)? {
        guard let state = state, let balance = balance, let marketInfo = marketInfo else {
            return nil
        }

        if case .syncing = state, !expanded {
            return nil
        }

        let currencyValue = CurrencyValue(currency: currency, value: balance * marketInfo.rate)

        guard let formattedValue = ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.01)) else {
            return nil
        }

        return (text: formattedValue, dimmed: state != .synced || marketInfo.expired)
    }

    private func syncingInfo(state: AdapterState?, expanded: Bool) -> (progress: Int?, syncedUntil: String?)? {
        guard let state = state, case let .syncing(progress, lastBlockDate) = state, !expanded else {
            return nil
        }

        if let lastBlockDate = lastBlockDate {
            return (progress: progress, syncedUntil: DateHelper.instance.formatSyncedThroughDate(from: lastBlockDate))
        } else {
            return (progress: nil, syncedUntil: nil)
        }
    }

    private func receiveButtonEnabled(state: AdapterState?, expanded: Bool) -> Bool? {
        if !expanded {
            return nil
        }

        return state != nil
    }

    private func sendButtonEnabled(state: AdapterState?, expanded: Bool) -> Bool? {
        if !expanded {
            return nil
        }

        return state == .synced
    }

}

extension BalanceViewItemFactory: IBalanceViewItemFactory {

    func viewItem(item: BalanceItem, currency: Currency, expanded: Bool) -> BalanceViewItem {
        let coin = item.wallet.coin
        let state = item.state
        let marketInfo = item.marketInfo

        return BalanceViewItem(
                wallet: item.wallet,

                coinIconCode: coinIconCode(coin: coin, state: state),
                coinTitle: coin.title,
                coinValue: coinValue(state: state, balance: item.balanceTotal, coin: coin, expanded: expanded),
                lockedCoinValue: coinValueLocked(state: state, balanceLocked: item.balanceLocked, coin: coin, expanded: expanded),
                lockedVisible: item.balanceLocked != nil,
                blockchainBadge: coin.type.blockchainType,

                currencyValue: currencyValue(state: state, balance: item.balanceTotal, currency: currency, marketInfo: marketInfo, expanded: expanded),
                lockedCurrencyValue: currencyValue(state: state, balance: item.balanceLocked, currency: currency, marketInfo: marketInfo, expanded: expanded),
                rateValue: rateValue(currency: currency, marketInfo: marketInfo),
                diff: diff(marketInfo: marketInfo),
                blockChart: blockedChartCoins.blockedCoins.contains(coin.code),

                syncSpinnerProgress: syncSpinnerProgress(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state),
                syncingInfo: syncingInfo(state: state, expanded: expanded),

                receiveButtonEnabled: receiveButtonEnabled(state: state, expanded: expanded),
                sendButtonEnabled: sendButtonEnabled(state: state, expanded: expanded),

                expanded: expanded
        )
    }

    func headerViewItem(items: [BalanceItem], currency: Currency) -> BalanceHeaderViewItem {
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
                upToDate: upToDate
        )
    }

}

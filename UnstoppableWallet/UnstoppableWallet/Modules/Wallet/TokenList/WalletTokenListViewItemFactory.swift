import Foundation
import CurrencyKit
import MarketKit
import EvmKit

class WalletTokenListViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    private func topViewItem(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue) -> BalanceTopViewItem {
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
                primaryValue: primaryValue(item: item, balancePrimaryValue: balancePrimaryValue),
                secondaryInfo: secondaryInfo(item: item, balancePrimaryValue: balancePrimaryValue)
        )
    }

    private func secondaryInfo(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = item.state {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .customSyncing(main, secondary, _) = item.state {
            return .customSyncing(main: main, secondary: secondary)
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                    descriptionValue: (text: item.element.coin?.name, dimmed: false),
                    secondaryValue: secondaryValue(item: item, balancePrimaryValue: balancePrimaryValue, expanded: true),
                    diff: nil
            ))
        }
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

    private func primaryValue(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state)
        case .currency: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
        }
    }

    private func secondaryValue(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue, expanded: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
        case .currency: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
                text: ValueFormatter.instance.formatFull(value: value, decimalCount: decimalCount, symbol: symbol),
                dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?) -> (text: String?, dimmed: Bool) {
        guard let priceItem = priceItem else {
            return (text: "---", dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return (
                text: ValueFormatter.instance.formatFull(currencyValue: currencyValue),
                dimmed: state != .synced || priceItem.expired
        )
    }

}

extension WalletTokenListViewItemFactory {

    func viewItem(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue) -> WalletTokenViewItem {
        WalletTokenViewItem(
                element: item.element,
                topViewItem: topViewItem(item: item, balancePrimaryValue: balancePrimaryValue)
        )
    }

}

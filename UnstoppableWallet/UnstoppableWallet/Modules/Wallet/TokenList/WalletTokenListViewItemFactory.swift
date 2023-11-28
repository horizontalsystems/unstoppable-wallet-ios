import EvmKit
import Foundation
import MarketKit

class WalletTokenListViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    private func topViewItem(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceTopViewItem {
        let state = item.state
        let sendEnabled = state.spendAllowed(beforeSync: item.balanceData.sendBeforeSync)

        return BalanceTopViewItem(
            isMainNet: item.isMainNet,
            iconUrlString: iconUrlString(coin: item.element.coin, state: state),
            placeholderIconName: item.element.wallet?.token.placeholderImageName ?? "placeholder_circle_32",
            name: item.element.name,
            blockchainBadge: item.element.wallet?.badge,
            syncSpinnerProgress: syncSpinnerProgress(state: state),
            indefiniteSearchCircle: indefiniteSearchCircle(state: state),
            failedImageViewVisible: failedImageViewVisible(state: state),
            sendEnabled: sendEnabled,
            primaryValue: primaryValue(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden),
            secondaryInfo: secondaryInfo(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden)
        )
    }

    private func secondaryInfo(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = item.state {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .customSyncing(main, secondary, _) = item.state {
            return .customSyncing(main: main, secondary: secondary)
        } else if case .stopped = item.state {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                descriptionValue: (text: "balance.stopped".localized, dimmed: false),
                secondaryValue: nil,
                diff: nil
            ))
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                descriptionValue: (text: item.element.coin?.name, dimmed: false),
                secondaryValue: secondaryValue(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden, expanded: true),
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
            if let progress {
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

    private func primaryValue(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state, balanceHidden: balanceHidden)
        case .currency: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, balanceHidden: balanceHidden)
        }
    }

    private func secondaryValue(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool, expanded _: Bool) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, balanceHidden: balanceHidden)
        case .currency: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state, balanceHidden: balanceHidden)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, state: AdapterState, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        (
            text: balanceHidden ? BalanceHiddenManager.placeholder : ValueFormatter.instance.formatShort(value: value, decimalCount: decimalCount, symbol: symbol),
            dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        guard let priceItem else {
            return (text: "---", dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return (
            text: balanceHidden ? BalanceHiddenManager.placeholder : ValueFormatter.instance.formatShort(currencyValue: currencyValue),
            dimmed: state != .synced || priceItem.expired
        )
    }
}

extension WalletTokenListViewItemFactory {
    func viewItem(item: WalletTokenListService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceViewItem {
        BalanceViewItem(
            element: item.element,
            topViewItem: topViewItem(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden)
        )
    }
}

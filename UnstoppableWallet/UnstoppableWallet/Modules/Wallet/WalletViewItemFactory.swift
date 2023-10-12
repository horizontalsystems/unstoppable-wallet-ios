import Foundation
import CurrencyKit
import MarketKit
import EvmKit

class WalletViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    private func topViewItem(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceTopViewItem {
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
                primaryValue: balanceHidden ? nil : primaryValue(item: item, balancePrimaryValue: balancePrimaryValue),
                secondaryInfo: secondaryInfo(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden)
        )
    }

    private func secondaryInfo(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceSecondaryInfoViewItem {
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
                    descriptionValue: rateValue(rateItem: item.priceItem),
                    secondaryValue: balanceHidden ? nil : secondaryValue(item: item, balancePrimaryValue: balancePrimaryValue),
                    diff: diff(rateItem: item.priceItem)
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
        case .customSyncing(_, _, let progress): return progress == nil
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

    private func primaryValue(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state)
        case .currency: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
        }
    }

    private func secondaryValue(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
        case .currency: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, state: item.state)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, state: AdapterState, expanded: Bool = false) -> (text: String?, dimmed: Bool) {
        (
                text: ValueFormatter.instance.formatShort(value: value, decimalCount: decimalCount, symbol: symbol),
                dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?, expanded: Bool = false) -> (text: String?, dimmed: Bool) {
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

    private func headerButtons(account: Account?) -> [WalletModule.Button: ButtonState] {
        guard let account = account else {
            return [:]
        }
        switch account.type {
        case .cex(let cexAccount):
            let withdrawalEnabled = cexAccount.cex.withdrawalAllowed ? ButtonState.enabled : .disabled
            return [
                .deposit: .enabled,
                .withdraw: withdrawalEnabled
            ]
        case .evmPrivateKey, .hdExtendedKey, .mnemonic:
            return [
                .send: .enabled,
                .receive: .enabled,
                .swap: .enabled
            ]
        case .evmAddress, .tronAddress: return [:]
        }
    }

}

extension WalletViewItemFactory {

    func viewItem(item: WalletService.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceViewItem {
        BalanceViewItem(
                element: item.element,
                topViewItem: topViewItem(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden)
        )
    }

    func headerViewItem(totalItem: WalletService.TotalItem, balanceHidden: Bool, account: Account?) -> WalletModule.HeaderViewItem {
        let amount = balanceHidden ? "*****" : ValueFormatter.instance.formatShort(currencyValue: totalItem.currencyValue)

        let convertedValue: String
        if balanceHidden {
            convertedValue = "*****"
        } else if let value = totalItem.convertedValue, let formattedValue = ValueFormatter.instance.formatShort(coinValue: value) {
            convertedValue = "≈ \(formattedValue)"
        } else {
            convertedValue = "---"
        }

        return WalletModule.HeaderViewItem(
                amount: amount,
                amountExpired: balanceHidden ? false : totalItem.expired,
                convertedValue: convertedValue,
                convertedValueExpired: balanceHidden ? false : totalItem.convertedValueExpired,
                buttons: headerButtons(account: account)
        )
    }

}

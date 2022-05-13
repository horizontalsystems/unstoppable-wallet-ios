import Foundation
import CurrencyKit
import MarketKit
import EthereumKit

class WalletViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    init() {
    }

    private func topViewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceTopViewItem {
        let coin = item.wallet.coin
        let state = item.state

        return BalanceTopViewItem(
                isMainNet: item.isMainNet,
                iconUrlString: iconUrlString(wallet: item.wallet, state: state),
                placeholderIconName: item.wallet.coinType.placeholderImageName,
                coinCode: coin.code,
                blockchainBadge: item.wallet.badge,
                syncSpinnerProgress: syncSpinnerProgress(state: state),
                indefiniteSearchCircle: indefiniteSearchCircle(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state),
                coinValue: balanceHidden ? nil : coinValue(platformCoin: item.wallet.platformCoin, value: item.balanceData.balanceTotal, state: item.state, expanded: expanded),
                secondaryInfo: secondaryInfo(item: item, balanceHidden: balanceHidden, expanded: expanded)
        )
    }


    private func secondaryInfo(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = item.state, expanded {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .searchingTxs(count) = item.state, expanded {
            return .searchingTx(count: count)
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                    currencyValue: balanceHidden ? nil : currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem, expanded: expanded),
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
                coinValue: coinValue(platformCoin: item.wallet.platformCoin, value: item.balanceData.balanceLocked, state: item.state, expanded: true),
                currencyValue: currencyValue(value: item.balanceData.balanceLocked, state: item.state, priceItem: item.priceItem, expanded: true)
        )
    }

    private func buttonsViewItem(item: WalletService.Item, actionsHidden: Bool, expanded: Bool) -> BalanceButtonsViewItem? {
        guard expanded else {
            return nil
        }

        let sendButtonsState: ButtonState = actionsHidden ? .hidden : (item.state == .synced ? .enabled : .disabled)

        return BalanceButtonsViewItem(
                sendButtonState: sendButtonsState,
                receiveButtonState: .enabled,
                swapButtonState: actionsHidden ? .hidden : (item.wallet.coinType.swappable ? sendButtonsState : .hidden),
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
        default: return nil
        }
    }

    private func indefiniteSearchCircle(state: AdapterState) -> Bool {
        switch state {
        case .searchingTxs: return true
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

        let formattedValue = ValueFormatter.instance.format(currencyValue: rateItem.price, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        return (text: formattedValue, dimmed: rateItem.expired)
    }

    private func diff(rateItem: WalletCoinPriceService.Item?) -> (text: String, type: BalanceDiffType)? {
        guard let rateItem = rateItem else {
            return nil
        }

        let value = rateItem.diff

        guard let formattedValue = Self.diffFormatter.string(from: abs(value) as NSNumber) else {
            return nil
        }

        let sign = value.isSignMinus ? "-" : "+"
        return (text: "\(sign)\(formattedValue)%", type: rateItem.expired ? .dimmed : (value < 0 ? .negative : .positive))
    }

    private func coinValue(platformCoin: PlatformCoin, value: Decimal, state: AdapterState, expanded: Bool) -> (text: String?, dimmed: Bool) {
        (
                text: expanded ? ValueFormatter.instance.formatFullNew(value: value, decimalCount: platformCoin.decimals, symbol: nil) : ValueFormatter.instance.formatNew(value: value, decimalCount: platformCoin.decimals, symbol: nil),
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
                text: expanded ? ValueFormatter.instance.formatFullNew(currencyValue: currencyValue) : ValueFormatter.instance.formatNew(currencyValue: currencyValue),
                dimmed: state != .synced || priceItem.expired
        )
    }

}

extension WalletViewItemFactory {

    func viewItem(item: WalletService.Item, balanceHidden: Bool, actionsHidden: Bool, expanded: Bool) -> BalanceViewItem {
        BalanceViewItem(
                wallet: item.wallet,
                topViewItem: topViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
                lockedAmountViewItem: lockedAmountViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
                buttonsViewItem: buttonsViewItem(item: item, actionsHidden: actionsHidden, expanded: expanded)
        )
    }

    func headerViewItem(totalItem: WalletService.TotalItem, balanceHidden: Bool, watchAccount: Bool, watchAccountAddress: EthereumKit.Address?) -> WalletViewModel.HeaderViewItem {
        let currencyValue = CurrencyValue(currency: totalItem.currency, value: totalItem.amount)
        let amount = balanceHidden ? "*****" : ValueFormatter.instance.formatNew(currencyValue: currencyValue)

        let convertedValue: String
        if balanceHidden {
            convertedValue = "*****"
        } else if let value = totalItem.convertedValue, let formattedValue = ValueFormatter.instance.formatNew(coinValue: value) {
            convertedValue = "≈ \(formattedValue)"
        } else {
            convertedValue = "---"
        }

        return WalletViewModel.HeaderViewItem(
                amount: amount,
                amountExpired: balanceHidden ? false : totalItem.expired,
                convertedValue: convertedValue,
                convertedValueExpired: balanceHidden ? false : totalItem.convertedValueExpired,
                manageWalletsHidden: watchAccount,
                address: watchAccount ? watchAccountAddress?.eip55 : nil
        )
    }

}

extension WalletViewItemFactory {

    private static let diffFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

}

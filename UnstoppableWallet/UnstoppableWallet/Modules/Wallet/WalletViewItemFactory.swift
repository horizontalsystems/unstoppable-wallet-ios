import Foundation
import XRatesKit
import CurrencyKit
import MarketKit

class WalletViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    init() {
    }

    private func topViewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceTopViewItem {
        let coin = item.wallet.coin
        let state = item.state
        let rateItem = item.rateItem

        return BalanceTopViewItem(
                isMainNet: item.isMainNet,
                iconUrlString: iconUrlString(wallet: item.wallet, state: state),
                coinCode: coin.code,
                blockchainBadge: badge(wallet: item.wallet),
                syncSpinnerProgress: syncSpinnerProgress(state: state),
                indefiniteSearchCircle: indefiniteSearchCircle(state: state),
                failedImageViewVisible: failedImageViewVisible(state: state),
                currencyValue: balanceHidden ? nil : currencyValue(value: item.balanceData.balanceTotal, state: item.state, rateItem: rateItem),
                secondaryInfo: secondaryInfo(item: item, balanceHidden: balanceHidden, expanded: expanded)
        )
    }

    private func badge(wallet: WalletNew) -> String? {
        switch wallet.coinType {
        case .bitcoin, .litecoin:
            return wallet.coinSettings.derivation?.rawValue.uppercased()
        case .bitcoinCash:
            return wallet.coinSettings.bitcoinCashCoinType?.rawValue.uppercased()
        default:
            return wallet.coinType.blockchainType
        }
    }

    private func secondaryInfo(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = item.state, expanded {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .searchingTxs(count) = item.state, expanded {
            return .searchingTx(count: count)
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                    coinValue: balanceHidden ? nil : coinValue(platformCoin: item.wallet.platformCoin, value: item.balanceData.balanceTotal, state: item.state),
                    rateValue: rateValue(rateItem: item.rateItem),
                    diff: diff(rateItem: item.rateItem)
            ))
        }
    }

    private func lockedAmountViewItem(item: WalletService.Item, balanceHidden: Bool, expanded: Bool) -> BalanceLockedAmountViewItem? {
        guard item.balanceData.balanceLocked > 0, !balanceHidden, expanded else {
            return nil
        }

        return BalanceLockedAmountViewItem(
            coinValue: coinValue(platformCoin: item.wallet.platformCoin, value: item.balanceData.balanceLocked, state: item.state),
                currencyValue: currencyValue(value: item.balanceData.balanceLocked, state: item.state, rateItem: item.rateItem)
        )
    }

    private func buttonsViewItem(item: WalletService.Item, expanded: Bool) -> BalanceButtonsViewItem? {
        guard expanded else {
            return nil
        }

        let sendButtonsState: ButtonState = item.state == .synced ? .enabled : .disabled

        return BalanceButtonsViewItem(
                sendButtonState: sendButtonsState,
                receiveButtonState: .enabled,
                swapButtonState: item.wallet.coinType.swappable ? sendButtonsState : .hidden,
                chartButtonState: item.rateItem != nil ? .enabled : .disabled
        )
    }

    private func iconUrlString(wallet: WalletNew, state: AdapterState) -> String? {
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

    private func rateValue(rateItem: WalletRateService.Item?) -> (text: String?, dimmed: Bool) {
        guard let rateItem = rateItem else {
            return (text: "n/a".localized, dimmed: true)
        }

        let formattedValue = ValueFormatter.instance.format(currencyValue: rateItem.rate, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
        return (text: formattedValue, dimmed: rateItem.expired)
    }

    private func diff(rateItem: WalletRateService.Item?) -> (text: String, type: BalanceDiffType)? {
        guard let rateItem = rateItem else {
            return nil
        }

        let value = rateItem.diff24h

        guard let formattedValue = Self.diffFormatter.string(from: abs(value) as NSNumber) else {
            return nil
        }

        let sign = value.isSignMinus ? "-" : "+"
        return (text: "\(sign)\(formattedValue)%", type: rateItem.expired ? .dimmed : (value.isSignMinus ? .negative : .positive))
    }

    private func coinValue(platformCoin: PlatformCoin, value: Decimal, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
                text: ValueFormatter.instance.format(coinValueNew: CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: value), showCode: false, fractionPolicy: .threshold(high: 0.01, low: 0)),
                dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, rateItem: WalletRateService.Item?) -> (text: String?, dimmed: Bool) {
        guard let rateItem = rateItem else {
            return (text: "---", dimmed: true)
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
                topViewItem: topViewItem(item: item, balanceHidden: balanceHidden, expanded: expanded),
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

extension WalletViewItemFactory {

    private static let diffFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        return formatter
    }()

}

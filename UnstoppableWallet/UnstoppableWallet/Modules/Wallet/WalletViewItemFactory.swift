import EvmKit
import Foundation
import MarketKit

class WalletViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    private func topViewItem(item: WalletServiceOld.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceTopViewItem {
        let state = item.state

        return BalanceTopViewItem(
            isMainNet: item.isMainNet,
            coin: stateAwareCoin(coin: item.wallet.coin, state: state),
            placeholderIconName: item.wallet.token.placeholderImageName,
            name: item.wallet.coin.code,
            blockchainBadge: item.wallet.badge,
            syncSpinnerProgress: syncSpinnerProgress(state: state),
            indefiniteSearchCircle: indefiniteSearchCircle(state: state),
            failedImageViewVisible: failedImageViewVisible(state: state),
            primaryValue: balanceHidden ? nil : primaryValue(item: item, balancePrimaryValue: balancePrimaryValue),
            secondaryInfo: secondaryInfo(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden)
        )
    }

    private func secondaryInfo(item: WalletServiceOld.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceSecondaryInfoViewItem {
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

    private func stateAwareCoin(coin: Coin?, state: AdapterState) -> Coin? {
        switch state {
        case .notSynced: return nil
        default: return coin
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
        case let .customSyncing(_, _, progress): return progress == nil
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
        guard let rateItem else {
            return (text: "n/a".localized, dimmed: true)
        }

        let formattedValue = ValueFormatter.instance.formatFull(currencyValue: rateItem.price)
        return (text: formattedValue, dimmed: rateItem.expired)
    }

    private func diff(rateItem: WalletCoinPriceService.Item?) -> (text: String, type: BalanceDiffType)? {
        guard let rateItem, let value = rateItem.diff else {
            return nil
        }

        guard let formattedValue = ValueFormatter.instance.format(percentValue: value, signType: .always) else {
            return nil
        }

        return (text: formattedValue, type: rateItem.expired ? .dimmed : (value < 0 ? .negative : .positive))
    }

    private func primaryValue(item: WalletServiceOld.Item, balancePrimaryValue: BalancePrimaryValue) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.wallet.decimals, state: item.state)
        case .currency: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
        }
    }

    private func secondaryValue(item: WalletServiceOld.Item, balancePrimaryValue: BalancePrimaryValue) -> (text: String?, dimmed: Bool) {
        switch balancePrimaryValue {
        case .coin: return currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
        case .currency: return coinValue(value: item.balanceData.balanceTotal, decimalCount: item.wallet.decimals, state: item.state)
        }
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, state: AdapterState, expanded _: Bool = false) -> (text: String?, dimmed: Bool) {
        (
            text: ValueFormatter.instance.formatShort(value: value, decimalCount: decimalCount, symbol: symbol),
            dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, state: AdapterState, priceItem: WalletCoinPriceService.Item?, expanded: Bool = false) -> (text: String?, dimmed: Bool) {
        guard let priceItem else {
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
        guard let account, !account.watchAccount else {
            return [:]
        }
        switch account.type {
        case .evmPrivateKey, .hdExtendedKey, .mnemonic:
            return [
                .send: .enabled,
                .receive: .enabled,
                .swap: AppConfig.swapEnabled ? .enabled : .hidden,
            ]
        case .stellarSecretKey:
            return [
                .send: .enabled,
                .receive: .enabled,
            ]
        case .evmAddress, .tronAddress, .tonAddress, .stellarAccount, .btcAddress: return [:]
        }
    }
}

extension WalletViewItemFactory {
    func viewItem(item: WalletServiceOld.Item, balancePrimaryValue: BalancePrimaryValue, balanceHidden: Bool) -> BalanceViewItem {
        BalanceViewItem(
            wallet: item.wallet,
            topViewItem: topViewItem(item: item, balancePrimaryValue: balancePrimaryValue, balanceHidden: balanceHidden)
        )
    }

    func headerViewItem(totalItem: WalletServiceOld.TotalItem, balanceHidden: Bool, buttonHidden: Bool, account: Account?) -> WalletModule.HeaderViewItem {
        let amount = balanceHidden ? BalanceHiddenManager.placeholder : ValueFormatter.instance.formatShort(currencyValue: totalItem.currencyValue)

        let convertedValue: String
        if balanceHidden {
            convertedValue = BalanceHiddenManager.placeholder
        } else if let value = totalItem.convertedValue, let formattedValue = value.formattedShort() {
            convertedValue = "≈ \(formattedValue)"
        } else {
            convertedValue = "---"
        }

        return WalletModule.HeaderViewItem(
            amount: amount,
            amountExpired: balanceHidden ? false : totalItem.expired,
            convertedValue: convertedValue,
            convertedValueExpired: balanceHidden ? false : totalItem.convertedValueExpired,
            buttons: buttonHidden ? [:] : headerButtons(account: account)
        )
    }
}

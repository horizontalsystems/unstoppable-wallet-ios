import Foundation
import MarketKit

class WalletTokenBalanceViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    func buttons(item: WalletTokenBalanceService.BalanceItem?) -> [WalletModule.Button: ButtonState] {
        guard let item else {
            return [:]
        }

        var buttons = [WalletModule.Button: ButtonState]()

        if item.watchAccount {
            buttons[.address] = .enabled
        } else {
            buttons[.send] = .enabled
            buttons[.receive] = .enabled

            if AppConfig.swapEnabled, item.wallet.token.swappable {
                buttons[.swap] = .enabled
            }
        }

        buttons[.chart] = item.priceItem != nil ? .enabled : .disabled

        return buttons
    }

    func headerViewItem(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> WalletTokenBalanceViewModel.ViewItem {
        let state = item.state

        return WalletTokenBalanceViewModel.ViewItem(
            isMainNet: item.isMainNet,
            coin: stateAwareCoin(coin: item.wallet.coin, state: state),
            placeholderIconName: item.wallet.token.placeholderImageName,
            syncSpinnerProgress: syncSpinnerProgress(state: state),
            indefiniteSearchCircle: indefiniteSearchCircle(state: state),
            failedImageViewVisible: failedImageViewVisible(state: state),
            balanceValue: balanceValue(item: item, balanceHidden: balanceHidden),
            descriptionValue: descriptionValue(item: item, balanceHidden: balanceHidden),
            customStates: customStates(item: item, balanceHidden: balanceHidden)
        )
    }

    private func descriptionValue(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        if case let .syncing(progress, lastBlockDate) = item.state {
            var text = ""
            if let progress {
                text = "balance.syncing_percent".localized("\(progress)%")
            } else {
                text = "balance.syncing".localized
            }

            if let syncedUntil = lastBlockDate.map({ DateHelper.instance.formatSyncedThroughDate(from: $0) }) {
                text += " - " + "balance.synced_through".localized(syncedUntil)
            }

            return (text: text, dimmed: failedImageViewVisible(state: item.state))
        } else if case let .customSyncing(main, secondary, _) = item.state {
            let text = [main, secondary].compactMap { $0 }.joined(separator: " - ")
            return (text: text, dimmed: failedImageViewVisible(state: item.state))
        } else if case .stopped = item.state {
            return (text: "balance.stopped".localized, dimmed: failedImageViewVisible(state: item.state))
        } else {
            return secondaryValue(item: item, balanceHidden: balanceHidden)
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
        case let .syncing(progress, _), let .customSyncing(_, _, progress):
            return progress.map { max(minimumProgress, $0) } ?? infiniteProgress
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

    private func balanceValue(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        coinValue(value: item.balanceData.balanceTotal, decimalCount: item.wallet.decimals, symbol: item.wallet.coin.code, balanceHidden: balanceHidden, state: item.state)
    }

    private func secondaryValue(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        currencyValue(value: item.balanceData.balanceTotal, balanceHidden: balanceHidden, state: item.state, priceItem: item.priceItem)
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, balanceHidden: Bool, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
            text: balanceHidden ? BalanceHiddenManager.placeholder : ValueFormatter.instance.formatFull(value: value, decimalCount: decimalCount, symbol: symbol),
            dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, balanceHidden: Bool, state: AdapterState, priceItem: WalletCoinPriceService.Item?) -> (text: String?, dimmed: Bool) {
        guard let priceItem else {
            return (text: "---", dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return (
            text: balanceHidden ? BalanceHiddenManager.placeholder : ValueFormatter.instance.formatFull(currencyValue: currencyValue),
            dimmed: state != .synced || priceItem.expired
        )
    }

    private func customStates(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> [WalletTokenBalanceViewModel.BalanceCustomStateViewItem] {
        item.balanceData
            .customStates
            .map {
                let value = coinValue(value: $0.value, decimalCount: item.wallet.decimals, symbol: item.wallet.coin.code, balanceHidden: balanceHidden, state: item.state)

                var action = WalletTokenBalanceViewModel.CustomStateAction.none

                if let balanceData = item.balanceData as? ZCashVerifiedBalanceData, balanceData.transparent > ZcashAdapter.minimalThreshold {
                    action = .unshield(balanceData.transparent)
                }

                return .init(
                    title: $0.title,
                    amountValue: value,
                    infoTitle: $0.infoTitle,
                    infoDescription: $0.infoDescription,
                    action: action
                )
            }
    }
}

import Foundation
import CurrencyKit
import MarketKit

class WalletTokenBalanceViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    func buttons(item: WalletTokenBalanceService.BalanceItem?) -> [WalletModule.Button: ButtonState] {
        guard let item else {
            return [:]
        }

        var buttons = [WalletModule.Button: ButtonState]()

        switch item.element {
        case .wallet(let wallet):
            if item.watchAccount {
                buttons[.address] = .enabled
            } else {
                let sendButtonState: ButtonState = item.state == .synced ? .enabled : .disabled

                buttons[.send] = sendButtonState
                buttons[.receive] = .enabled

                if wallet.token.swappable {
                    buttons[.swap] = sendButtonState
                }
            }
        case .cexAsset(let cexAsset):
            buttons[.withdraw] = cexAsset.withdrawEnabled ? .enabled : .disabled
            buttons[.deposit] = cexAsset.depositEnabled ? .enabled : .disabled
        }

        buttons[.chart] = item.priceItem != nil ? .enabled : .disabled

        return buttons
    }

    func headerViewItem(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> WalletTokenBalanceViewModel.ViewItem {
        let state = item.state

        return WalletTokenBalanceViewModel.ViewItem(
                isMainNet: item.isMainNet,
                iconUrlString: iconUrlString(coin: item.element.coin, state: state),
                placeholderIconName: item.element.wallet?.token.placeholderImageName ?? "placeholder_circle_32",
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
            var text: String = ""
            if let progress = progress {
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

    private func iconUrlString(coin: Coin?, state: AdapterState) -> String? {
        switch state {
        case .notSynced: return nil
        default: return coin?.imageUrl
        }
    }

    private func syncSpinnerProgress(state: AdapterState) -> Int? {
        switch state {
        case let .syncing(progress, _), .customSyncing(_, _, let progress):
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
        coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, symbol: item.element.coin?.code, balanceHidden: balanceHidden, state: item.state)
    }

    private func secondaryValue(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> (text: String?, dimmed: Bool) {
        currencyValue(value: item.balanceData.balanceTotal, balanceHidden: balanceHidden, state: item.state, priceItem: item.priceItem)
    }

    private func coinValue(value: Decimal, decimalCount: Int, symbol: String? = nil, balanceHidden: Bool, state: AdapterState) -> (text: String?, dimmed: Bool) {
        (
                text: balanceHidden ? "*****" : ValueFormatter.instance.formatFull(value: value, decimalCount: decimalCount, symbol: symbol),
                dimmed: state != .synced
        )
    }

    private func currencyValue(value: Decimal, balanceHidden: Bool, state: AdapterState, priceItem: WalletCoinPriceService.Item?) -> (text: String?, dimmed: Bool) {
        guard let priceItem = priceItem else {
            return (text: "---", dimmed: true)
        }

        let price = priceItem.price
        let currencyValue = CurrencyValue(currency: price.currency, value: value * price.value)

        return (
                text: balanceHidden ? "*****" : ValueFormatter.instance.formatFull(currencyValue: currencyValue),
                dimmed: state != .synced || priceItem.expired
        )
    }

    private func customStates(item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> [WalletTokenBalanceViewModel.BalanceCustomStateViewItem] {
        let stateItems = [
            CustomStateItem(
                    title: "balance.token.locked".localized,
                    amount: item.balanceData.locked,
                    infoTitle: "balance.token.locked.info.title".localized,
                    infoDescription: "balance.token.locked.info.description".localized
            ),
            CustomStateItem(
                    title: "balance.token.staked".localized,
                    amount: item.balanceData.staked,
                    infoTitle: "balance.token.staked.info.title".localized,
                    infoDescription: "balance.token.staked.info.description".localized
            ),
            CustomStateItem(
                    title: "balance.token.frozen".localized,
                    amount: item.balanceData.frozen,
                    infoTitle: "balance.token.frozen.info.title".localized,
                    infoDescription: "balance.token.frozen.info.description".localized
            ),
        ]

        return stateItems
                .compactMap {
                    lockedAmountViewItem(
                            customStateItem: $0,
                            item: item,
                            balanceHidden: balanceHidden
                    )
                }
    }

    private func lockedAmountViewItem(customStateItem: CustomStateItem, item: WalletTokenBalanceService.BalanceItem, balanceHidden: Bool) -> WalletTokenBalanceViewModel.BalanceCustomStateViewItem? {
        guard customStateItem.amount > 0 else {
            return nil
        }

        let value = coinValue(value: customStateItem.amount, decimalCount: item.element.decimals, symbol: item.element.coin?.code, balanceHidden: balanceHidden, state: item.state)
        return .init(
                title: customStateItem.title,
                amountValue: value,
                infoTitle: customStateItem.infoTitle,
                infoDescription: customStateItem.infoDescription
        )
    }

}

extension WalletTokenBalanceViewItemFactory {

    private struct CustomStateItem {
        let title: String
        let amount: Decimal
        let infoTitle: String
        let infoDescription: String
    }

}

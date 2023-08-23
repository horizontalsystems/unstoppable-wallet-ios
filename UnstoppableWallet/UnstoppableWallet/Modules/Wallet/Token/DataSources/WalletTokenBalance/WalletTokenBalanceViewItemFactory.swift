import Foundation
import CurrencyKit
import MarketKit

class WalletTokenBalanceViewItemFactory {
    private let minimumProgress = 10
    private let infiniteProgress = 50

    private func headerButtons(wallet: Wallet) -> [WalletModule.Button: ButtonState] {
//        switch account.type {
//        case .cex(let cexAccount):
//            let withdrawalEnabled = cexAccount.cex.withdrawalAllowed ? ButtonState.enabled : .disabled
//            return [
//                .deposit: .enabled,
//                .withdraw: withdrawalEnabled
//            ]
//        case .evmPrivateKey, .hdExtendedKey, .mnemonic:
//            return [
//                .send: .enabled,
//                .receive: .enabled,
//                .swap: .enabled
//            ]
//        case .evmAddress, .tronAddress: return [:]
//        }
        [
            .deposit: .enabled,
            .withdraw: .enabled
        ]
    }

    func headerViewItem(item: WalletTokenBalanceService.Item) -> BalanceTopViewItem {
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
                primaryValue: primaryValue(item: item),
                secondaryInfo: secondaryInfo(item: item)
        )
    }

    private func secondaryInfo(item: WalletTokenBalanceService.Item) -> BalanceSecondaryInfoViewItem {
        if case let .syncing(progress, lastBlockDate) = item.state {
            return .syncing(progress: progress, syncedUntil: lastBlockDate.map { DateHelper.instance.formatSyncedThroughDate(from: $0) })
        } else if case let .customSyncing(main, secondary, _) = item.state {
            return .customSyncing(main: main, secondary: secondary)
        } else {
            return .amount(viewItem: BalanceSecondaryAmountViewItem(
                    descriptionValue: (text: item.element.coin?.name, dimmed: false),
                    secondaryValue: secondaryValue(item: item),
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

    private func primaryValue(item: WalletTokenBalanceService.Item) -> (text: String?, dimmed: Bool) {
        coinValue(value: item.balanceData.balanceTotal, decimalCount: item.element.decimals, symbol: item.element.coin?.code, state: item.state)
    }

    private func secondaryValue(item: WalletTokenBalanceService.Item) -> (text: String?, dimmed: Bool) {
        currencyValue(value: item.balanceData.balanceTotal, state: item.state, priceItem: item.priceItem)
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

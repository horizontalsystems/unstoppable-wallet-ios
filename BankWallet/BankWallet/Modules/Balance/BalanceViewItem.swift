import Foundation
import DeepDiff
import XRatesKit

struct BalanceViewItem {
    let wallet: Wallet

    let coinIconCode: String?
    let coinTitle: String
    let coinValue: (text: String, dimmed: Bool)?
    let lockedCoinValue: (text: String, dimmed: Bool)?
    let blockchainBadge: String?

    let currencyValue: (text: String, dimmed: Bool)?
    let lockedCurrencyValue: (text: String, dimmed: Bool)?
    let rateValue: (text: String, dimmed: Bool)?
    let diff: Decimal?
    let chartInfo: ChartInfo?
    let chartNotAvailableVisible: Bool

    let syncSpinnerProgress: Int?
    let failedImageViewVisible: Bool
    let syncingInfo: (progress: Int?, syncedUntil: String?)?

    let receiveButtonEnabled: Bool?
    let sendButtonEnabled: Bool?

    let expanded: Bool
}

extension BalanceViewItem: DiffAware {

    public var diffId: Wallet {
        wallet
    }

    static func compareContent(_ a: BalanceViewItem, _ b: BalanceViewItem) -> Bool {
        let compareCoin =
                a.coinIconCode == b.coinIconCode &&
                a.coinTitle == b.coinTitle &&
                a.coinValue?.text == b.coinValue?.text &&
                a.coinValue?.dimmed == b.coinValue?.dimmed &&
                a.lockedCoinValue?.text == b.lockedCoinValue?.text &&
                a.lockedCoinValue?.dimmed == b.lockedCoinValue?.dimmed &&
                a.blockchainBadge == b.blockchainBadge

        let compareCurrency =
                a.currencyValue?.text == b.currencyValue?.text &&
                a.currencyValue?.dimmed == b.currencyValue?.dimmed &&
                a.lockedCurrencyValue?.text == b.lockedCurrencyValue?.text &&
                a.lockedCurrencyValue?.dimmed == b.lockedCurrencyValue?.dimmed &&
                a.rateValue?.text == b.rateValue?.text &&
                a.rateValue?.dimmed == b.rateValue?.dimmed &&
                a.diff == b.diff &&
                a.chartInfo?.points == b.chartInfo?.points &&
                a.chartNotAvailableVisible == b.chartNotAvailableVisible

        let compareOther =
                a.syncSpinnerProgress == b.syncSpinnerProgress &&
                a.failedImageViewVisible == b.failedImageViewVisible &&
                a.syncingInfo?.progress == b.syncingInfo?.progress &&
                a.syncingInfo?.syncedUntil == b.syncingInfo?.syncedUntil &&
                a.receiveButtonEnabled == b.receiveButtonEnabled &&
                a.sendButtonEnabled == b.sendButtonEnabled &&
                a.expanded == b.expanded

        return compareCoin && compareCurrency && compareOther
    }

}

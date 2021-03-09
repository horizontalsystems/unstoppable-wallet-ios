import Foundation
import DeepDiff
import XRatesKit
import CoinKit

struct BalanceViewItem {
    let wallet: Wallet

    let topViewItem: BalanceTopViewItem
    let separatorVisible: Bool
    let amountViewItem: BalanceAmountViewItem?
    let lockedAmountViewItem: BalanceLockedAmountViewItem?
    let buttonsViewItem: BalanceButtonsViewItem?
}

struct BalanceTopViewItem {
    let iconCoinType: CoinType?
    let coinTitle: String
    let blockchainBadge: String?

    let rateValue: (text: String, dimmed: Bool)?
    let diff: (value: Decimal, dimmed: Bool)?

    let syncSpinnerProgress: Int?
    let indefiniteSearchCircle: Bool
    let failedImageViewVisible: Bool
}

enum BalanceAmountViewItem {
    case amount(coinValue: (text: String?, dimmed: Bool), currencyValue: (text: String?, dimmed: Bool)?)
    case searchingTx(count: Int)
    case syncing(progress: Int?, syncedUntil: String?)
}

struct BalanceLockedAmountViewItem {
    let lockedCoinValue: (text: String?, dimmed: Bool)
    let lockedCurrencyValue: (text: String?, dimmed: Bool)?
}

struct BalanceButtonsViewItem {
    let receiveButtonState: ButtonState
    let sendButtonState: ButtonState
    let swapButtonState: ButtonState
}

extension BalanceTopViewItem: Equatable {

    static func ==(lhs: BalanceTopViewItem, rhs: BalanceTopViewItem) -> Bool {
        lhs.iconCoinType == rhs.iconCoinType &&
                lhs.coinTitle == rhs.coinTitle &&
                lhs.blockchainBadge == rhs.blockchainBadge &&
                lhs.rateValue?.text == rhs.rateValue?.text &&
                lhs.rateValue?.dimmed == rhs.rateValue?.dimmed &&
                lhs.diff?.value == rhs.diff?.value &&
                lhs.diff?.dimmed == rhs.diff?.dimmed &&
                lhs.syncSpinnerProgress == rhs.syncSpinnerProgress &&
                lhs.failedImageViewVisible == rhs.failedImageViewVisible
    }

}

extension BalanceAmountViewItem: Equatable {

    static func ==(lhs: BalanceAmountViewItem, rhs: BalanceAmountViewItem) -> Bool {
        switch (lhs, rhs) {
        case (.amount(let lhsCoinValue, let lhsCurrencyValue), .amount(let rhsCoinValue, let rhsCurrencyValue)):
            return lhsCoinValue.text == rhsCoinValue.text &&
                    lhsCoinValue.dimmed == rhsCoinValue.dimmed &&
                    lhsCurrencyValue?.text == rhsCurrencyValue?.text &&
                    lhsCurrencyValue?.dimmed == rhsCurrencyValue?.dimmed
        case (.searchingTx(let lhsCount), .searchingTx(let rhsCount)):
            return lhsCount == rhsCount
        case (.syncing(let lhsProgress, let lhsSyncedUntil), .syncing(let rhsProgress, let rhsSyncedUntil)):
            return lhsProgress == rhsProgress &&
                    lhsSyncedUntil == rhsSyncedUntil
        default: return false
        }
    }

}

extension BalanceLockedAmountViewItem: Equatable {

    static func ==(lhs: BalanceLockedAmountViewItem, rhs: BalanceLockedAmountViewItem) -> Bool {
        lhs.lockedCoinValue.text == rhs.lockedCoinValue.text &&
                lhs.lockedCoinValue.dimmed == rhs.lockedCoinValue.dimmed &&
                lhs.lockedCurrencyValue?.text == rhs.lockedCurrencyValue?.text &&
                lhs.lockedCurrencyValue?.dimmed == rhs.lockedCurrencyValue?.dimmed
    }

}

extension BalanceButtonsViewItem: Equatable {

    static func ==(lhs: BalanceButtonsViewItem, rhs: BalanceButtonsViewItem) -> Bool {
        lhs.receiveButtonState == rhs.receiveButtonState &&
                lhs.sendButtonState == rhs.sendButtonState &&
                lhs.swapButtonState == rhs.swapButtonState
    }

}

extension BalanceViewItem: DiffAware {

    public var diffId: Wallet {
        wallet
    }

    static func compareContent(_ a: BalanceViewItem, _ b: BalanceViewItem) -> Bool {
        a.topViewItem == b.topViewItem &&
                a.separatorVisible == b.separatorVisible &&
                a.amountViewItem == b.amountViewItem &&
                a.lockedAmountViewItem == b.lockedAmountViewItem &&
                a.buttonsViewItem == b.buttonsViewItem
    }

}

import Foundation
import DeepDiff
import XRatesKit
import CoinKit

struct BalanceViewItem {
    let wallet: Wallet

    let topViewItem: BalanceTopViewItem
    let lockedAmountViewItem: BalanceLockedAmountViewItem?
    let buttonsViewItem: BalanceButtonsViewItem?
}

struct BalanceTopViewItem {
    let iconCoinType: CoinType?
    let coinCode: String
    let blockchainBadge: String?

    let syncSpinnerProgress: Int?
    let indefiniteSearchCircle: Bool
    let failedImageViewVisible: Bool

    let currencyValue: (text: String?, dimmed: Bool)?
    let secondaryInfo: BalanceSecondaryInfoViewItem
}

enum BalanceSecondaryInfoViewItem {
    case amount(viewItem: BalanceSecondaryAmountViewItem)
    case searchingTx(count: Int)
    case syncing(progress: Int?, syncedUntil: String?)
}

struct BalanceSecondaryAmountViewItem {
    let coinValue: (text: String?, dimmed: Bool)?
    let rateValue: (text: String?, dimmed: Bool)
    let diff: (text: String, type: BalanceDiffType)?
}

enum BalanceDiffType {
    case dimmed
    case positive
    case negative
}

struct BalanceLockedAmountViewItem {
    let coinValue: (text: String?, dimmed: Bool)
    let currencyValue: (text: String?, dimmed: Bool)?
}

struct BalanceButtonsViewItem {
    let sendButtonState: ButtonState
    let receiveButtonState: ButtonState
    let swapButtonState: ButtonState
    let chartButtonState: ButtonState
}

extension BalanceTopViewItem: Equatable {

    static func ==(lhs: BalanceTopViewItem, rhs: BalanceTopViewItem) -> Bool {
        lhs.iconCoinType == rhs.iconCoinType &&
                lhs.coinCode == rhs.coinCode &&
                lhs.blockchainBadge == rhs.blockchainBadge &&
                lhs.syncSpinnerProgress == rhs.syncSpinnerProgress &&
                lhs.indefiniteSearchCircle == rhs.indefiniteSearchCircle &&
                lhs.failedImageViewVisible == rhs.failedImageViewVisible &&
                lhs.currencyValue?.text == rhs.currencyValue?.text &&
                lhs.currencyValue?.dimmed == rhs.currencyValue?.dimmed &&
                lhs.secondaryInfo == rhs.secondaryInfo
    }

}

extension BalanceSecondaryInfoViewItem: Equatable {

    static func ==(lhs: BalanceSecondaryInfoViewItem, rhs: BalanceSecondaryInfoViewItem) -> Bool {
        switch (lhs, rhs) {
        case (.amount(let lhsViewItem), .amount(let rhsViewItem)):
            return lhsViewItem == rhsViewItem
        case (.searchingTx(let lhsCount), .searchingTx(let rhsCount)):
            return lhsCount == rhsCount
        case (.syncing(let lhsProgress, let lhsSyncedUntil), .syncing(let rhsProgress, let rhsSyncedUntil)):
            return lhsProgress == rhsProgress &&
                    lhsSyncedUntil == rhsSyncedUntil
        default: return false
        }
    }

}

extension BalanceSecondaryAmountViewItem: Equatable {

    static func ==(lhs: BalanceSecondaryAmountViewItem, rhs: BalanceSecondaryAmountViewItem) -> Bool {
        lhs.coinValue?.text == rhs.coinValue?.text &&
                lhs.coinValue?.dimmed == rhs.coinValue?.dimmed &&
                lhs.rateValue.text == rhs.rateValue.text &&
                lhs.rateValue.dimmed == rhs.rateValue.dimmed &&
                lhs.diff?.text == rhs.diff?.text &&
                lhs.diff?.type == rhs.diff?.type
    }

}

extension BalanceLockedAmountViewItem: Equatable {

    static func ==(lhs: BalanceLockedAmountViewItem, rhs: BalanceLockedAmountViewItem) -> Bool {
        lhs.coinValue.text == rhs.coinValue.text &&
                lhs.coinValue.dimmed == rhs.coinValue.dimmed &&
                lhs.currencyValue?.text == rhs.currencyValue?.text &&
                lhs.currencyValue?.dimmed == rhs.currencyValue?.dimmed
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
                a.lockedAmountViewItem == b.lockedAmountViewItem &&
                a.buttonsViewItem == b.buttonsViewItem
    }

}

import Foundation
import DeepDiff
import MarketKit

struct BalanceViewItem {
    let wallet: Wallet

    let topViewItem: BalanceTopViewItem
    let lockedAmountViewItem: BalanceLockedAmountViewItem?
    let buttonsViewItem: BalanceButtonsViewItem?
}

struct BalanceTopViewItem {
    let isMainNet: Bool
    let iconUrlString: String?
    let placeholderIconName: String
    let coinCode: String
    let blockchainBadge: String?

    let syncSpinnerProgress: Int?
    let indefiniteSearchCircle: Bool
    let failedImageViewVisible: Bool

    let primaryValue: (text: String?, dimmed: Bool)?
    let secondaryInfo: BalanceSecondaryInfoViewItem
}

enum BalanceSecondaryInfoViewItem {
    case amount(viewItem: BalanceSecondaryAmountViewItem)
    case syncing(progress: Int?, syncedUntil: String?)
    case customSyncing(main: String, secondary: String?)
}

struct BalanceSecondaryAmountViewItem {
    let secondaryValue: (text: String?, dimmed: Bool)?
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
    let addressButtonState: ButtonState
    let swapButtonState: ButtonState
    let chartButtonState: ButtonState
}

extension BalanceTopViewItem: Equatable {

    static func ==(lhs: BalanceTopViewItem, rhs: BalanceTopViewItem) -> Bool {
        lhs.isMainNet == rhs.isMainNet &&
                lhs.iconUrlString == rhs.iconUrlString &&
                lhs.coinCode == rhs.coinCode &&
                lhs.blockchainBadge == rhs.blockchainBadge &&
                lhs.syncSpinnerProgress == rhs.syncSpinnerProgress &&
                lhs.indefiniteSearchCircle == rhs.indefiniteSearchCircle &&
                lhs.failedImageViewVisible == rhs.failedImageViewVisible &&
                lhs.primaryValue?.text == rhs.primaryValue?.text &&
                lhs.primaryValue?.dimmed == rhs.primaryValue?.dimmed &&
                lhs.secondaryInfo == rhs.secondaryInfo
    }

}

extension BalanceSecondaryInfoViewItem: Equatable {

    static func ==(lhs: BalanceSecondaryInfoViewItem, rhs: BalanceSecondaryInfoViewItem) -> Bool {
        switch (lhs, rhs) {
        case (.amount(let lhsViewItem), .amount(let rhsViewItem)):
            return lhsViewItem == rhsViewItem
        case (.syncing(let lhsProgress, let lhsSyncedUntil), .syncing(let rhsProgress, let rhsSyncedUntil)):
            return lhsProgress == rhsProgress &&
                    lhsSyncedUntil == rhsSyncedUntil
        case (.customSyncing(let lMain, let lSecondary), .customSyncing(let rMain, let rSecondary)):
            return lMain == rMain &&
                    lSecondary ?? "" == rSecondary ?? ""
        default: return false
        }
    }

}

extension BalanceSecondaryAmountViewItem: Equatable {

    static func ==(lhs: BalanceSecondaryAmountViewItem, rhs: BalanceSecondaryAmountViewItem) -> Bool {
        lhs.secondaryValue?.text == rhs.secondaryValue?.text &&
                lhs.secondaryValue?.dimmed == rhs.secondaryValue?.dimmed &&
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
        lhs.sendButtonState == rhs.sendButtonState &&
                lhs.receiveButtonState == rhs.receiveButtonState &&
                lhs.addressButtonState == rhs.addressButtonState &&
                lhs.swapButtonState == rhs.swapButtonState &&
                lhs.chartButtonState == rhs.chartButtonState
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


extension BalanceViewItem: CustomStringConvertible {

    var description: String {
        "[topViewItem: \(topViewItem); lockedAmountViewItem: ; buttonsViewItem: ]"
    }

}

extension BalanceTopViewItem: CustomStringConvertible {

    var description: String {
        "[iconUrlString: \(iconUrlString ?? "nil"); coinCode: \(coinCode); blockchainBadge: \(blockchainBadge ?? "nil"); syncSpinnerProgress: \(syncSpinnerProgress.map { "\($0)" } ?? "nil"); indefiniteSearchCircle: \(indefiniteSearchCircle); failedImageViewVisible: \(failedImageViewVisible); primaryValue: \(primaryValue.map { "[text: \($0.text ?? "nil"); dimmed: \($0.dimmed)]" } ?? "nil"); secondaryInfo: \(secondaryInfo)]"
    }

}

extension BalanceSecondaryInfoViewItem: CustomStringConvertible {

    var description: String {
        switch self {
        case .amount(let viewItem): return "[amount: \(viewItem)]"
        case .syncing(let progress, let syncedUntil): return "[syncing: [progress: \(progress.map { "\($0)" } ?? "nil"); syncedUntil: \(syncedUntil ?? "nil")]]"
        case .customSyncing(let left, let right): return "[\([left, right].compactMap { $0 }.joined(separator: " : "))]"
        }
    }

}

extension BalanceSecondaryAmountViewItem: CustomStringConvertible {

    var description: String {
        "[secondaryValue: \(secondaryValue.map { "[text: \($0.text ?? "nil"); dimmed: \($0.dimmed)]" } ?? "nil"); rateValue: \("[text: \(rateValue.text ?? "nil"); dimmed: \(rateValue.dimmed)]"); diff: \(diff.map { "[text: \($0.text); type: \($0.type)]" } ?? "nil")]"
    }

}

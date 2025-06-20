import DeepDiff
import Foundation
import MarketKit

struct BalanceViewItem {
    let wallet: Wallet
    let topViewItem: BalanceTopViewItem
}

struct BalanceTopViewItem {
    let isMainNet: Bool
    let coin: Coin?
    let placeholderIconName: String?
    let name: String
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
    let descriptionValue: (text: String?, dimmed: Bool)
    let secondaryValue: (text: String?, dimmed: Bool)?
    let diff: (text: String, type: BalanceDiffType)?
}

enum BalanceDiffType {
    case dimmed
    case positive
    case negative
}

extension BalanceTopViewItem: Equatable {
    static func == (lhs: BalanceTopViewItem, rhs: BalanceTopViewItem) -> Bool {
        lhs.isMainNet == rhs.isMainNet &&
            lhs.coin == rhs.coin &&
            lhs.name == rhs.name &&
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
    static func == (lhs: BalanceSecondaryInfoViewItem, rhs: BalanceSecondaryInfoViewItem) -> Bool {
        switch (lhs, rhs) {
        case let (.amount(lhsViewItem), .amount(rhsViewItem)):
            return lhsViewItem == rhsViewItem
        case let (.syncing(lhsProgress, lhsSyncedUntil), .syncing(rhsProgress, rhsSyncedUntil)):
            return lhsProgress == rhsProgress &&
                lhsSyncedUntil == rhsSyncedUntil
        case let (.customSyncing(lMain, lSecondary), .customSyncing(rMain, rSecondary)):
            return lMain == rMain &&
                lSecondary ?? "" == rSecondary ?? ""
        default: return false
        }
    }
}

extension BalanceSecondaryAmountViewItem: Equatable {
    static func == (lhs: BalanceSecondaryAmountViewItem, rhs: BalanceSecondaryAmountViewItem) -> Bool {
        lhs.secondaryValue?.text == rhs.secondaryValue?.text &&
            lhs.secondaryValue?.dimmed == rhs.secondaryValue?.dimmed &&
            lhs.descriptionValue.text == rhs.descriptionValue.text &&
            lhs.descriptionValue.dimmed == rhs.descriptionValue.dimmed &&
            lhs.diff?.text == rhs.diff?.text &&
            lhs.diff?.type == rhs.diff?.type
    }
}

extension BalanceViewItem: DiffAware {
    public var diffId: Wallet {
        wallet
    }

    static func compareContent(_ a: BalanceViewItem, _ b: BalanceViewItem) -> Bool {
        a.topViewItem == b.topViewItem
    }
}

extension BalanceViewItem: CustomStringConvertible {
    var description: String {
        "[topViewItem: \(topViewItem); buttonsViewItem: ]"
    }
}

extension BalanceTopViewItem: CustomStringConvertible {
    var description: String {
        "[coin: \(coin?.name ?? "nil"); name: \(name); blockchainBadge: \(blockchainBadge ?? "nil"); syncSpinnerProgress: \(syncSpinnerProgress.map { "\($0)" } ?? "nil"); indefiniteSearchCircle: \(indefiniteSearchCircle); failedImageViewVisible: \(failedImageViewVisible); primaryValue: \(primaryValue.map { "[text: \($0.text ?? "nil"); dimmed: \($0.dimmed)]" } ?? "nil"); secondaryInfo: \(secondaryInfo)]"
    }
}

extension BalanceSecondaryInfoViewItem: CustomStringConvertible {
    var description: String {
        switch self {
        case let .amount(viewItem): return "[amount: \(viewItem)]"
        case let .syncing(progress, syncedUntil): return "[syncing: [progress: \(progress.map { "\($0)" } ?? "nil"); syncedUntil: \(syncedUntil ?? "nil")]]"
        case let .customSyncing(left, right): return "[\([left, right].compactMap { $0 }.joined(separator: " : "))]"
        }
    }
}

extension BalanceSecondaryAmountViewItem: CustomStringConvertible {
    var description: String {
        "[secondaryValue: \(secondaryValue.map { "[text: \($0.text ?? "nil"); dimmed: \($0.dimmed)]" } ?? "nil"); rateValue: \("[text: \(descriptionValue.text ?? "nil"); dimmed: \(descriptionValue.dimmed)]"); diff: \(diff.map { "[text: \($0.text); type: \($0.type)]" } ?? "nil")]"
    }
}

import Foundation
import XCTest
import Cuckoo
@testable import Bank_Dev_T

class TestError: Error {}

func equal<T, T2: AnyObject>(to value: T, type: T2.Type) -> ParameterMatcher<T> {
    return equal(to: value) { $0 as! T2 === $1 as! T2 }
}

extension XCTestCase {
    func waitForMainQueue() {
        let e = expectation(description: "Wait for Main Queue")
        DispatchQueue.main.async { e.fulfill() }
        waitForExpectations(timeout: 2)
    }
}

extension CoinValue: Equatable {
    public static func ==(lhs: CoinValue, rhs: CoinValue) -> Bool {
        return lhs.coinCode == rhs.coinCode && lhs.value == rhs.value
    }
}

extension BalanceViewItem: Equatable {
    public static func ==(lhs: BalanceViewItem, rhs: BalanceViewItem) -> Bool {
        return lhs.coinValue == rhs.coinValue && lhs.exchangeValue == rhs.exchangeValue
    }
}

extension LatestRateData: Equatable {
    public static func ==(lhs: LatestRateData, rhs: LatestRateData) -> Bool {
        return lhs.values == rhs.values && lhs.date == rhs.date
    }
}

extension AmountInfo: Equatable {
    public static func ==(lhs: AmountInfo, rhs: AmountInfo) -> Bool {
        switch (lhs, rhs) {
        case (let .coinValue(lhsCoinValue), let .coinValue(rhsCoinValue)): return lhsCoinValue == rhsCoinValue
        case (let .currencyValue(lhsCurrencyValue), let .currencyValue(rhsCurrencyValue)): return lhsCurrencyValue == rhsCurrencyValue
        default: return false
        }
    }
}

extension FeeError: Equatable {
    public static func ==(lhs: FeeError, rhs: FeeError) -> Bool {
        switch (lhs, rhs) {
        case (let .erc20error(lhsCoinCode, lhsFee), let .erc20error(rhsCoinCode, rhsFee)): return lhsCoinCode == rhsCoinCode && lhsFee == rhsFee
        }
    }
}

extension FeeInfo: Equatable {
    public static func ==(lhs: FeeInfo, rhs: FeeInfo) -> Bool {
        return lhs.primaryFeeInfo == rhs.primaryFeeInfo && lhs.secondaryFeeInfo == rhs.secondaryFeeInfo && lhs.error == rhs.error
    }
}

extension HintInfo: Equatable {
    public static func ==(lhs: HintInfo, rhs: HintInfo) -> Bool {
        switch (lhs, rhs) {
        case (let .amount(lhsAmountInfo), let .amount(rhsAmountInfo)): return lhsAmountInfo == rhsAmountInfo
        case (let .error(lhsError), let .error(rhsError)): return lhsError == rhsError
        default: return false
        }
    }
}

extension AddressInfo: Equatable {
    public static func ==(lhs: AddressInfo, rhs: AddressInfo) -> Bool {
        switch (lhs, rhs) {
        case (let .address(lhsAddress), let .address(rhsAddress)): return lhsAddress == rhsAddress
        case (let .invalidAddress(lhsAddress, lhsError), let .invalidAddress(rhsAddress, rhsError)): return lhsAddress == rhsAddress && lhsError == rhsError
        default: return false
        }
    }
}

extension LockoutState: Equatable {
    public static func ==(lhs: LockoutState, rhs: LockoutState) -> Bool {
        switch (lhs, rhs) {
        case (let .unlocked(lhsAttempts), let .unlocked(rhsAttempts)): return lhsAttempts == rhsAttempts
        case (let .locked(lhsDate), let .locked(rhsDate)): return lhsDate.compare(rhsDate) == .orderedSame
        default: return false
        }
    }
}

extension FullTransactionRecord: Equatable {
    public static func ==(lhs: FullTransactionRecord, rhs: FullTransactionRecord) -> Bool {
        return lhs.sections == rhs.sections
    }
}

extension FullTransactionSection: Equatable {
    public static func ==(lhs: FullTransactionSection, rhs: FullTransactionSection) -> Bool {
        return lhs.title == rhs.title && lhs.items == rhs.items
    }
}

extension FullTransactionItem: Equatable {
    public static func ==(lhs: FullTransactionItem, rhs: FullTransactionItem) -> Bool {
        return lhs.value == rhs.value && lhs.title == rhs.title && lhs.clickable == rhs.clickable && lhs.showExtra == rhs.showExtra && lhs.url == rhs.url
    }
}

extension FeeRatePriority {
    public static func ==(lhs: FeeRatePriority, rhs: FeeRatePriority) -> Bool {
        switch (lhs, rhs) {
        case (.lowest, .lowest): return true
        case (.low, .low): return true
        case (.medium, .medium): return true
        case (.high, .high): return true
        case (.highest, .highest): return true
        default: return false
        }
    }
}

extension Rate: Equatable {
    public static func ==(lhs: Rate, rhs: Rate) -> Bool {
        return lhs.value == rhs.value && lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode && lhs.date == rhs.date && lhs.isLatest == rhs.isLatest
    }
}

extension EnabledCoin: Equatable {

    public static func ==(lhs: EnabledCoin, rhs: EnabledCoin) -> Bool {
        return lhs.coinCode == rhs.coinCode && lhs.order == rhs.order
    }

}

extension SecuritySettingsUnlockType: Equatable {
    public static func ==(lhs: SecuritySettingsUnlockType, rhs: SecuritySettingsUnlockType) -> Bool {
        switch (lhs, rhs) {
        case (.biometry(let lIsOn), .biometry(let rIsOn)): return lIsOn == rIsOn
        }
    }
}

extension BalanceHeaderViewItem: Equatable {
    public static func ==(lhs: BalanceHeaderViewItem, rhs: BalanceHeaderViewItem) -> Bool {
        return lhs.currencyValue == rhs.currencyValue && lhs.upToDate == rhs.upToDate
    }
}

extension BalanceItem: Equatable {
    public static func ==(lhs: BalanceItem, rhs: BalanceItem) -> Bool {
        return lhs.state == rhs.state && lhs.balance == rhs.balance
    }
}

extension AdapterState {
    public static func ==(lhs: AdapterState, rhs: AdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case (.syncing(let lProgress, let lLastBlockDate), .syncing(let rProgress, let rLastBlockDate)): return lProgress == rProgress && lLastBlockDate == rLastBlockDate
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }
}

extension BalanceSortType: Equatable {
    public static func ==(lhs: BalanceSortType, rhs: BalanceSortType) -> Bool {
        switch (lhs, rhs) {
        case (.value, .value): return true
        case (.az, .az): return true
        case (.manual, .manual): return true
        default: return false
        }
    }
}


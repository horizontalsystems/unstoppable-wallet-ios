import Foundation
import XCTest
@testable import Bank_Dev_T

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

extension Currency: Equatable {
    public static func ==(lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }
}

extension CurrencyValue: Equatable {
    public static func ==(lhs: CurrencyValue, rhs: CurrencyValue) -> Bool {
        return lhs.currency == rhs.currency && lhs.value == rhs.value
    }
}

extension BalanceViewItem: Equatable {
    public static func ==(lhs: BalanceViewItem, rhs: BalanceViewItem) -> Bool {
        return lhs.coinValue == rhs.coinValue && lhs.exchangeValue == rhs.exchangeValue
    }
}

extension LatestRate: Equatable {
    public static func ==(lhs: LatestRate, rhs: LatestRate) -> Bool {
        return lhs.value == rhs.value && lhs.timestamp == rhs.timestamp
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

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

extension TransactionFilterItem: Equatable {
    public static func ==(lhs: TransactionFilterItem, rhs: TransactionFilterItem) -> Bool {
        return lhs.coinCode == rhs.coinCode && lhs.name == rhs.name
    }
}

extension TransactionRecord {
    convenience init(transactionHash: String, coinCode: String, timestamp: Double) {
        self.init()

        self.transactionHash = transactionHash
        self.coinCode = coinCode
        self.timestamp = timestamp
    }
}

extension LatestRate: Equatable {
    public static func ==(lhs: LatestRate, rhs: LatestRate) -> Bool {
        return lhs.value == rhs.value && lhs.timestamp == rhs.timestamp
    }
}

extension Rate {
    convenience init(coinCode: String, currencyCode: String, value: Double, timestamp: Double) {
        self.init()

        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.value = value
        self.timestamp = timestamp
    }
}

extension TransactionAddress {
    convenience init(address: String, mine: Bool) {
        self.init()

        self.address = address
        self.mine = mine
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

extension AmountError: Equatable {
    public static func ==(lhs: AmountError, rhs: AmountError) -> Bool {
        switch (lhs, rhs) {
        case (let .insufficientAmount(lhsAmountInfo), let .insufficientAmount(rhsAmountInfo)): return lhsAmountInfo == rhsAmountInfo
        }
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

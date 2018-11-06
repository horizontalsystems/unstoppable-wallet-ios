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
        return lhs.coin == rhs.coin && lhs.value == rhs.value
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

extension WalletViewItem: Equatable {
    public static func ==(lhs: WalletViewItem, rhs: WalletViewItem) -> Bool {
        return lhs.coinValue == rhs.coinValue && lhs.exchangeValue == rhs.exchangeValue
    }
}

extension TransactionFilterItem: Equatable {
    public static func ==(lhs: TransactionFilterItem, rhs: TransactionFilterItem) -> Bool {
        return lhs.coin == rhs.coin && lhs.name == rhs.name
    }
}

extension TransactionRecord {
    convenience init(transactionHash: String, coin: String, timestamp: Int) {
        self.init()

        self.transactionHash = transactionHash
        self.coin = coin
        self.timestamp = timestamp
    }
}

extension Rate {
    convenience init(coin: String, currencyCode: String, value: Double, timestamp: Double) {
        self.init()

        self.coin = coin
        self.currencyCode = currencyCode
        self.value = value
        self.timestamp = timestamp
    }
}

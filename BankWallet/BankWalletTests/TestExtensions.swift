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

extension EnabledWallet: Equatable {

    public static func ==(lhs: EnabledWallet, rhs: EnabledWallet) -> Bool {
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

extension Wallet {

    static func mock(coin: Coin = Coin.mock(), account: Account = Account.mock(), syncMode: SyncMode? = nil) -> Wallet {
        return Wallet(coin: coin, account: account, syncMode: syncMode)
    }

}

extension Coin {

    static func mock(title: String = "Bitcoin", code: CoinCode = "BTC", type: CoinType = .bitcoin) -> Coin {
        return Coin(title: title, code: code, type: type)
    }

}

extension Account {

    static func mock(id: String? = nil, name: String? = nil, type: AccountType = .mnemonic(words: [], derivation: .bip44, salt: nil), backedUp: Bool = true, defaultSyncMode: SyncMode? = nil) -> Account {
        let uuid = UUID().uuidString
        return Account(id: id ?? uuid, name: name ?? uuid, type: type, backedUp: backedUp, defaultSyncMode: defaultSyncMode)
    }

}

extension ManageAccountViewItemState: Equatable {

    public static func ==(lhs: ManageAccountViewItemState, rhs: ManageAccountViewItemState) -> Bool {
        switch (lhs, rhs) {
        case (.linked(let lhsBackedUp), .linked(let rhsBackedUp)): return lhsBackedUp == rhsBackedUp
        case (.notLinked, .notLinked): return true
        default: return false
        }
    }

}

extension JsonApiProvider.RequestObject: Equatable {

    public static func ==(lhs: JsonApiProvider.RequestObject, rhs: JsonApiProvider.RequestObject) -> Bool {
        switch (lhs, rhs) {
        case (.get(let lhsUrl, let lhsParams), .get(let rhsUrl, let rhsParams)): return lhsUrl == rhsUrl
        case (.post(let lhsUrl, let lhsParams), .post(let rhsUrl, let rhsParams)): return lhsUrl == rhsUrl
        default: return false
        }
    }

}

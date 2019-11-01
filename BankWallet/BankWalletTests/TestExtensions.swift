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
        return lhs.coin == rhs.coin && lhs.value == rhs.value
    }
}

extension BalanceViewItem: Equatable {
    public static func ==(lhs: BalanceViewItem, rhs: BalanceViewItem) -> Bool {
        return lhs.coinValue == rhs.coinValue && lhs.exchangeValue == rhs.exchangeValue
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
        case (.low, .low): return true
        case (.medium, .medium): return true
        case (.high, .high): return true
        default: return false
        }
    }
}

extension EnabledWallet: Equatable {

    public static func ==(lhs: EnabledWallet, rhs: EnabledWallet) -> Bool {
        lhs.coinId == rhs.coinId && lhs.order == rhs.order
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

    static func mock(id: String? = nil, title: String? = nil, code: CoinCode? = nil, decimal: Int = 8, type: CoinType = .bitcoin) -> Coin {
        let randomNumber = Int.random(in: 0..<1000)
        return Coin(id: id ?? "BTC_\(randomNumber)", title: title ?? "Bitcoin_\(randomNumber)", code: code ?? "BTC_\(randomNumber)", decimal: decimal, type: type)
    }

}

extension Currency {

    static func mock(code: String = "USD", symbol: String = "$", decimal: Int = 2) -> Currency {
        return Currency(code: code, symbol: symbol, decimal: decimal)
    }

}

extension Account {

    static func mock(id: String? = nil, name: String? = nil, type: AccountType = .mnemonic(words: [], derivation: .bip44, salt: nil), backedUp: Bool = true, defaultSyncMode: SyncMode? = nil) -> Account {
        let uuid = UUID().uuidString
        return Account(id: id ?? uuid, name: name ?? uuid, type: type, backedUp: backedUp, defaultSyncMode: defaultSyncMode)
    }

}

extension JsonApiProvider.RequestObject: Equatable {

    public static func ==(lhs: JsonApiProvider.RequestObject, rhs: JsonApiProvider.RequestObject) -> Bool {
        switch (lhs, rhs) {
        case (.get(let lhsUrl, _), .get(let rhsUrl, _)): return lhsUrl == rhsUrl
        case (.post(let lhsUrl, _), .post(let rhsUrl, _)): return lhsUrl == rhsUrl
        default: return false
        }
    }

}

extension CreateWalletViewItem {

    static func mock(title: String? = nil, code: String? = nil, selected: Bool = false) -> CreateWalletViewItem {
        let randomNumber = Int.random(in: 0..<1000)
        return CreateWalletViewItem(title: title ?? "Bitcoin_\(randomNumber)", code: code ?? "BTC_\(randomNumber)", selected: selected)
    }

}

extension CreateWalletViewItem: Equatable {

    public static func ==(lhs: CreateWalletViewItem, rhs: CreateWalletViewItem) -> Bool {
        return lhs.title == rhs.title && lhs.code == rhs.code
    }

}

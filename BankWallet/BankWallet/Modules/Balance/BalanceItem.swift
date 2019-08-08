import Foundation
import DeepDiff

// to support diff in balance presenter BalanceItem need to be struct
struct BalanceItem {
    let wallet: Wallet

    var balance: Decimal
    var state: AdapterState
    var rate: Rate?

    init(wallet: Wallet, balance: Decimal = 0, state: AdapterState = .synced) {
        self.wallet = wallet
        self.balance = balance
        self.state = state
    }

}

extension BalanceItem: DiffAware {

    public var diffId: String {
        return wallet.coin.code
    }

    static func compareContent(_ a: BalanceItem, _ b: BalanceItem) -> Bool {
        return
                a.balance   == b.balance &&
                a.state     == b.state &&
                a.rate      == b.rate
    }

}

import Foundation

struct BalanceData: Equatable {
    let balance: Decimal
    let locked: Decimal
    let staked: Decimal
    let frozen: Decimal

    init(balance: Decimal, locked: Decimal = 0, staked: Decimal = 0, frozen: Decimal = 0) {
        self.balance = balance
        self.locked = locked
        self.staked = staked
        self.frozen = frozen
    }

    var balanceTotal: Decimal {
        balance + locked + staked + frozen
    }

    static func ==(lhs: BalanceData, rhs: BalanceData) -> Bool {
        lhs.balance == rhs.balance &&
                lhs.locked == rhs.locked &&
                lhs.staked == rhs.staked &&
                lhs.frozen == rhs.frozen
    }
}

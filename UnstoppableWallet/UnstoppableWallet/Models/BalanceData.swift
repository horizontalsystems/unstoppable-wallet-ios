import Foundation

struct BalanceData: Equatable {
    let balance: Decimal
    let balanceLocked: Decimal

    init(balance: Decimal, balanceLocked: Decimal = 0) {
        self.balance = balance
        self.balanceLocked = balanceLocked
    }

    var balanceTotal: Decimal {
        balance + balanceLocked
    }

    static func ==(lhs: BalanceData, rhs: BalanceData) -> Bool {
        lhs.balance == rhs.balance && lhs.balanceLocked == rhs.balanceLocked
    }
}

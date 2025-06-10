import Foundation

class BalanceData: Equatable {
    let total: Decimal
    let available: Decimal

    init(balance: Decimal) {
        total = balance
        available = balance
    }

    init(total: Decimal, available: Decimal) {
        self.total = total
        self.available = available
    }

    static func == (lhs: BalanceData, rhs: BalanceData) -> Bool {
        lhs.available == rhs.available && lhs.total == rhs.total
    }
}

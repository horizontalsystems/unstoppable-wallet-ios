import Foundation

public struct BalanceData: Hashable {
    public let total: Decimal
    public let available: Decimal

    init(balance: Decimal) {
        total = balance
        available = balance
    }

    init(total: Decimal, available: Decimal) {
        self.total = total
        self.available = available
    }
}

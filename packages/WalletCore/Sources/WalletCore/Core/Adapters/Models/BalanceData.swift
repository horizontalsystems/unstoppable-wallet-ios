import Foundation

public struct BalanceData: Hashable {
    public let total: Decimal
    public let available: Decimal

    public init(balance: Decimal) {
        total = balance
        available = balance
    }

    public init(total: Decimal, available: Decimal) {
        self.total = total
        self.available = available
    }
}

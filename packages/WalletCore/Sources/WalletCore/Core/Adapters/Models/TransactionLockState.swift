import Foundation

public struct TransactionLockState {
    public let locked: Bool
    public let date: Date

    public init(locked: Bool, date: Date) {
        self.locked = locked
        self.date = date
    }
}

extension TransactionLockState: Equatable {
    public static func == (lhs: TransactionLockState, rhs: TransactionLockState) -> Bool {
        lhs.locked == rhs.locked && lhs.date == rhs.date
    }
}

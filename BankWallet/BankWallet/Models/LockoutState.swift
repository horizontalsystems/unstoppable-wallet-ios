import Foundation

enum LockoutState {
    case unlocked(attemptsLeft: Int?)
    case locked(timeFrame: TimeInterval)
}

enum LockoutStateNew {
    case unlocked(attemptsLeft: Int?)
    case locked(till: Date)
}

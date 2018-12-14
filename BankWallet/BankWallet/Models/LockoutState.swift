import Foundation

enum LockoutState {
    case unlocked(attemptsLeft: Int?)
    case locked(till: Date)
}

import Foundation

class LockoutManagerNew: ILockoutManagerNew {

    var currentState: LockoutStateNew {
        return .unlocked(attemptsLeft: nil)
    }

    func didFailUnlock() {

    }

}

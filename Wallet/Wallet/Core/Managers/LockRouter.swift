import Foundation

class LockRouter {

    func showUnlock(delegate: UnlockDelegate?) {
        UnlockPinRouter.module(unlockDelegate: delegate)
    }

}

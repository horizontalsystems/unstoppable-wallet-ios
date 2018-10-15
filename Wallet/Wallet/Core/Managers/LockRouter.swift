import Foundation

class LockRouter: ILockRouter {

    func showUnlock(delegate: IUnlockDelegate?) {
        UnlockPinRouter.module(unlockDelegate: delegate)
    }

}

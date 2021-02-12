import PinKit

class LockScreenPresenter {
    private let router: ILockScreenRouter
    private let appStart: Bool

    init(router: ILockScreenRouter, appStart: Bool) {
        self.router = router
        self.appStart = appStart
    }

}

extension LockScreenPresenter: IUnlockDelegate {

    func onUnlock() {
        if appStart {
            router.reloadAppInterface()
        }
    }

    func onCancelUnlock() {
    }

}

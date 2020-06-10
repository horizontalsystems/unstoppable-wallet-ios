import PinKit

class LockScreenPresenter {
    private let router: ILockScreenRouter

    init(router: ILockScreenRouter) {
        self.router = router
    }

}

extension LockScreenPresenter: IUnlockDelegate {

    func onUnlock() {
        router.dismiss()
    }

    func onCancelUnlock() {
    }

}

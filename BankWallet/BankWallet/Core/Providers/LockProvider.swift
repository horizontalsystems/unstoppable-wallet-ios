import PinKit

class LockProvider {
    public var viewController: UIViewController?
}

extension LockProvider: ILockProvider {

    public func lockScreenModule(delegate: IUnlockDelegate, appStart: Bool) -> UIViewController {
        LockScreenRouter.module(pinKit: App.shared.pinKit, appStart: false)
    }

}

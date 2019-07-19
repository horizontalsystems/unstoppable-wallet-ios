import UIKit

class PasscodeLockRouter {

    private func show(module: UIViewController) {
        UIApplication.shared.keyWindow?.set(newRootController: module)
    }

}

extension PasscodeLockRouter: IPasscodeLockRouter {

    func showNoPasscode() {
        show(module: NoPasscodeRouter.module())
    }

    func showLaunch() {
        show(module: LaunchRouter.module())
    }

}

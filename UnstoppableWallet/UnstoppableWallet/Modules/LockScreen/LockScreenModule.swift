import UIKit
import PinKit

struct LockScreenModule {

    static func viewController(pinKit: PinKit.Kit, appStart: Bool) -> UIViewController {
        let unlockController = pinKit.unlockPinModule(
                biometryUnlockMode: .auto,
                insets: UIEdgeInsets(top: 0, left: 0, bottom: .margin12x, right: 0),
                cancellable: false,
                autoDismiss: !appStart,
                onUnlock: {
                    if appStart {
                        UIApplication.shared.windows.first { $0.isKeyWindow }?.set(newRootController: MainModule.instance())
                    }
                }
        )

        let viewController = LockScreenViewController(unlockViewController: unlockController)
        viewController.modalPresentationStyle = .fullScreen

        return viewController
    }

}

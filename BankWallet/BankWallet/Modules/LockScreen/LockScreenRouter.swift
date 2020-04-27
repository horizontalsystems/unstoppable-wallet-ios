import UIKit
import PinKit
import ThemeKit

class LockScreenRouter {
    weak var viewController: UIViewController?

    private let appStart: Bool

    init(appStart: Bool) {
        self.appStart = appStart
    }

}

extension LockScreenRouter: ILockScreenRouter {

    func showChart(coinCode: String, coinTitle: String) {
        viewController?.navigationController?.pushViewController(ChartRouter.module(coinCode: coinCode, coinTitle: coinTitle), animated: true)
    }

    func dismiss() {
        if appStart {
            UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module())
        } else {
            viewController?.dismiss(animated: false)
        }
    }

}

extension LockScreenRouter {

    static func module(pinKit: IPinKit, appStart: Bool) -> UIViewController {
        let router = LockScreenRouter(appStart: appStart)
        let presenter = LockScreenPresenter(router: router)

        let insets = UIEdgeInsets(top: LockScreenController.pageControlHeight, left: 0, bottom: 60, right: 0)
        let rateListController = RateListRouter.module(delegate: presenter, topMargin: LockScreenController.pageControlHeight)
        let unlockController = pinKit.unlockPinModule(delegate: presenter, biometryUnlockMode: .enabled, insets: insets, cancellable: false)

        let viewController = LockScreenController(viewControllers: [unlockController, rateListController])
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return ThemeNavigationController(rootViewController: viewController)
    }

}

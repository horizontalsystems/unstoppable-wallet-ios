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

        let insets = UIEdgeInsets(top: LockScreenController.pageControlHeight, left: 0, bottom: .margin12x, right: 0)
        let unlockController = pinKit.unlockPinModule(delegate: presenter, biometryUnlockMode: .enabled, insets: insets, cancellable: false)

        let rateListInsets = UIEdgeInsets(top: LockScreenController.pageControlHeight, left: 0, bottom: 0, right: 0)
        let rateListController = RateListRouter.module(chartOpener: presenter, additionalSafeAreaInsets: rateListInsets)
        let rateTopListController = RateTopListRouter.module(chartOpener: presenter, additionalSafeAreaInsets: rateListInsets)

        let viewController = LockScreenController(viewControllers: [unlockController, rateListController, rateTopListController])
        router.viewController = viewController

        viewController.modalTransitionStyle = .crossDissolve

        return ThemeNavigationController(rootViewController: viewController)
    }

}

import UIKit

class DerivationSettingConfirmationRouter {
    weak var viewController: UIViewController?
}

extension DerivationSettingConfirmationRouter: IDerivationSettingConfirmationRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension DerivationSettingConfirmationRouter {

    static func module(coinTitle: String, setting: DerivationSetting, delegate: IDerivationSettingConfirmationDelegate) -> UIViewController {
        let router = DerivationSettingConfirmationRouter()
        let presenter = DerivationSettingConfirmationPresenter(coinTitle: coinTitle, setting: setting, router: router)
        let viewController = DerivationSettingConfirmationViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

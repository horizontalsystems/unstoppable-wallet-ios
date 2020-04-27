import UIKit
import ThemeKit

class DerivationSettingRouter {
    weak var viewController: UIViewController?
}

extension DerivationSettingRouter: IDerivationSettingRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension DerivationSettingRouter {

    static func module(coin: Coin, currentDerivation: MnemonicDerivation, delegate: IDerivationSettingDelegate) -> UIViewController {
        let router = DerivationSettingRouter()
        let presenter = DerivationSettingPresenter(coin: coin, currentDerivation: currentDerivation, router: router)
        let viewController = DerivationSettingViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

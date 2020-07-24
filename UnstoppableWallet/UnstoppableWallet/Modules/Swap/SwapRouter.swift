import UIKit
import ThemeKit
import UniswapKit

class SwapRouter {
    weak var viewController: UIViewController?
}

extension SwapRouter: ISwapRouter {

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SwapRouter {

    static func module(wallet: Wallet) -> UIViewController? {
        guard let swapKit = App.shared.swapKitManager.kit(account: wallet.account) else {
            return nil
        }

        let decimalParser = SendAmountDecimalParser()

        let router = SwapRouter()
        let interactor = SwapInteractor(swapKit: swapKit)
        let presenter = SwapPresenter(interactor: interactor, router: router, factory: SwapViewItemFactory(), decimalParser: decimalParser, coinIn: wallet.coin)
        let viewController = SwapViewController(delegate: presenter)

        presenter.view = viewController
        interactor.delegate = presenter
        router.viewController = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}

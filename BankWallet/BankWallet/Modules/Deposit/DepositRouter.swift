import UIKit
import ActionSheet

class DepositRouter {
    weak var viewController: UIViewController?
}

extension DepositRouter: IDepositRouter {

    func share(address: String) {
        let activityViewController = UIActivityViewController(activityItems: [address], applicationActivities: [])
        viewController?.present(activityViewController, animated: true, completion: nil)
    }

}

extension DepositRouter {

    static func module(coin: Coin?) -> ActionSheetController {
        let router = DepositRouter()
        let interactor = DepositInteractor(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager, pasteboardManager: App.shared.pasteboardManager)
        let presenter = DepositPresenter(interactor: interactor, router: router, coin: coin)
        let viewController = DepositViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

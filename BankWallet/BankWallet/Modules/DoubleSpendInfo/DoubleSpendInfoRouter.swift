import UIKit
import ThemeKit

class DoubleSpendInfoRouter {

    static func module(txHash: String, conflictingTxHash: String) -> UIViewController {
        let interactor = DoubleSpendInfoInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = DoubleSpendInfoPresenter(interactor: interactor, txHash: txHash, conflictingTxHash: conflictingTxHash)
        let viewController = DoubleSpendInfoViewController(delegate: presenter)

        presenter.view = viewController

        return ThemeNavigationController(rootViewController: viewController)
    }

}

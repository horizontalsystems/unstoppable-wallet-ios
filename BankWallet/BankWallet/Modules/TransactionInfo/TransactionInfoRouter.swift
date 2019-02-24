import UIKit
import GrouviActionSheet

class TransactionInfoRouter {
    weak var viewController: UIViewController?
}

extension TransactionInfoRouter: ITransactionInfoRouter {

    func openFullInfo(transactionHash: String, coin: Coin) {
        viewController?.present(FullTransactionInfoRouter.module(transactionHash: transactionHash, coin: coin), animated: true)
    }

}

extension TransactionInfoRouter {

    static func module(viewItem: TransactionViewItem) -> ActionSheetController {
        let router = TransactionInfoRouter()

        let interactor = TransactionInfoInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = TransactionInfoPresenter(interactor: interactor, router: router, factory: TransactionViewItemFactory())
        let alertModel = TransactionInfoAlertModel(item: viewItem, delegate: presenter)

        interactor.delegate = presenter
        presenter.view = alertModel

        let viewController = ActionSheetController(withModel: alertModel, actionSheetThemeConfig: AppTheme.actionSheetConfig)
        viewController.backgroundColor = .crypto_Dark_Bars

        router.viewController = viewController

        return viewController
    }

}

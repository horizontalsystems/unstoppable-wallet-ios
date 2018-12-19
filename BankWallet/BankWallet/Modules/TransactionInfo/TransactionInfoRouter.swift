import UIKit
import GrouviActionSheet

class TransactionInfoRouter {
}

extension TransactionInfoRouter: ITransactionInfoRouter {
}

extension TransactionInfoRouter {

    static func module(transactionHash: String) -> ActionSheetController {
        let router = TransactionInfoRouter()
        let interactor = TransactionInfoInteractor(storage: App.shared.realmStorage, pasteboardManager: App.shared.pasteboardManager)
        let presenter = TransactionInfoPresenter(interactor: interactor, router: router, factory: App.shared.transactionViewItemFactory)
        let alertModel = TransactionInfoAlertModel(delegate: presenter, transactionHash: transactionHash)

        interactor.delegate = presenter
        presenter.view = alertModel

        let viewController = ActionSheetController(withModel: alertModel, actionSheetThemeConfig: AppTheme.actionSheetConfig)
        viewController.backgroundColor = .crypto_Dark_Bars
        return viewController
    }

}

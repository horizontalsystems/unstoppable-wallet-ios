import UIKit
import WalletKit

class TransactionsRouter {
    weak var viewController: UIViewController?
    var view: Any?
}

extension TransactionsRouter: ITransactionsRouter {

    func showTransactionInfo(transaction: TransactionRecordViewItem, coinCode: String, txHash: String) {
        view = TransactionInfoRouter.module(controller: viewController, transaction: transaction, coinCode: coinCode, txHash: txHash)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(adapterManager: App.shared.adapterManager, exchangeRateManager: ExchangeRateManager.shared)
        let presenter = TransactionsPresenter(interactor: interactor, router: router)
        let viewController = TransactionsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

import UIKit

class TransactionsRouter {
    weak var viewController: UIViewController?
    var view: Any?
}

extension TransactionsRouter: ITransactionsRouter {

    func showTransactionInfo(transaction: TransactionRecordViewItem, coin: Coin, txHash: String) {
        view = TransactionInfoRouter.module(controller: viewController, transaction: transaction, coin: coin, txHash: txHash)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(walletManager: App.shared.walletManager, exchangeRateManager: App.shared.exchangeRateManager)
        let presenter = TransactionsPresenter(interactor: interactor, router: router)
        let viewController = TransactionsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

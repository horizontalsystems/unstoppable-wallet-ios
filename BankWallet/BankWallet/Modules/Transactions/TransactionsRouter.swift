import UIKit

class TransactionsRouter {
    weak var viewController: UIViewController?
    var view: Any?
}

extension TransactionsRouter: ITransactionsRouter {

    func openTransactionInfo(transaction: TransactionRecordViewItem) {
        view = TransactionInfoRouter.module(controller: viewController, transaction: transaction)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(walletManager: App.shared.walletManager, exchangeRateManager: App.shared.exchangeRateManager, realmFactory: App.shared.realmFactory)
        let presenter = TransactionsPresenter(interactor: interactor, router: router)
        let viewController = TransactionsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

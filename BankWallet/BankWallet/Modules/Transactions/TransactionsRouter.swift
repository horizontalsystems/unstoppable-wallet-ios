import UIKit

class TransactionsRouter {
    weak var viewController: UIViewController?
    var view: Any?
}

extension TransactionsRouter: ITransactionsRouter {

    func openTransactionInfo(transaction: TransactionViewItem) {
        view = TransactionInfoRouter.module(controller: viewController, transaction: transaction)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let dataSource = TransactionRecordDataSource(realmFactory: App.shared.realmFactory)

        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(walletManager: App.shared.walletManager, exchangeRateManager: App.shared.rateManager, currencyManager: App.shared.currencyManager, dataSource: dataSource)
        let presenter = TransactionsPresenter(interactor: interactor, router: router)
        let viewController = TransactionsViewController(delegate: presenter)

        dataSource.delegate = interactor
        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

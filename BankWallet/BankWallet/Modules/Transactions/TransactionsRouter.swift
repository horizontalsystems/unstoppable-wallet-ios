import UIKit

class TransactionsRouter {
    weak var viewController: UIViewController?
}

extension TransactionsRouter: ITransactionsRouter {

    func openTransactionInfo(transactionHash: String) {
        viewController?.present(TransactionInfoRouter.module(transactionHash: transactionHash), animated: true)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let dataSource = TransactionRecordDataSource(realmFactory: App.shared.realmFactory)

        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(walletManager: App.shared.walletManager, exchangeRateManager: App.shared.rateManager, dataSource: dataSource)
        let presenter = TransactionsPresenter(interactor: interactor, router: router, factory: App.shared.transactionViewItemFactory)
        let viewController = TransactionsViewController(delegate: presenter)

        dataSource.delegate = interactor
        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

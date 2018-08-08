import UIKit
import WalletKit

class TransactionsRouter {
    weak var viewController: UIViewController?
}

extension TransactionsRouter: ITransactionsRouter {

    func showTransactionInfo(transaction: TransactionRecordViewItem, coinCode: String, txHash: String) {
        TransactionInfoRouter.module(transaction: transaction, coinCode: coinCode, txHash: txHash).show(fromController: viewController)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(storage: RealmStorage.shared, coinManager: Factory.instance.coinManager)
        let presenter = TransactionsPresenter(interactor: interactor, router: router)
        let viewController = TransactionsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

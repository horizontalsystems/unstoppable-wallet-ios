import UIKit
import ThemeKit

class TransactionsRouter {
    weak var viewController: UIViewController?
}

extension TransactionsRouter: ITransactionsRouter {

    func openTransactionInfo(viewItem: TransactionViewItem) {
        guard let module = TransactionInfoModule.instance(transaction: viewItem.record, wallet: viewItem.wallet) else {
            return
        }

        viewController?.present(ThemeNavigationController(rootViewController: module), animated: true)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let dataSource = TransactionRecordDataSourceOld(poolRepo: TransactionRecordPoolRepo(), itemsDataSource: TransactionViewItemDataSource(), metaDataSource: TransactionsMetadataDataSource(), factory: TransactionViewItemFactory())

        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(
                walletManager: App.shared.walletManager,
                adapterManager: App.shared.transactionAdapterManager,
                currencyKit: App.shared.currencyKit,
                rateManager: App.shared.rateManager,
                reachabilityManager: App.shared.reachabilityManager
        )
        let presenter = TransactionsPresenter(interactor: interactor, router: router, factory: TransactionViewItemFactory(), dataSource: dataSource)
        let viewController = TransactionsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

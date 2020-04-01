import UIKit

class TransactionsRouter {
    weak var viewController: UIViewController?
}

extension TransactionsRouter: ITransactionsRouter {

    func openTransactionInfo(viewItem: TransactionViewItem) {
        viewController?.present(TransactionInfoRouter.module(viewItem: viewItem), animated: true)
    }

}

extension TransactionsRouter {

    static func module() -> UIViewController {
        let dataSource = TransactionRecordDataSource(poolRepo: TransactionRecordPoolRepo(), itemsDataSource: TransactionViewItemDataSource(), metaDataSource: TransactionsMetadataDataSource(), factory: TransactionViewItemFactory(feeCoinProvider: App.shared.feeCoinProvider))

        let router = TransactionsRouter()
        let interactor = TransactionsInteractor(walletManager: App.shared.walletManager, adapterManager: App.shared.adapterManager, currencyKit: App.shared.currencyKit, rateManager: App.shared.rateManager, reachabilityManager: App.shared.reachabilityManager)
        let presenter = TransactionsPresenter(interactor: interactor, router: router, factory: TransactionViewItemFactory(feeCoinProvider: App.shared.feeCoinProvider), dataSource: dataSource)
        let viewController = TransactionsViewController(delegate: presenter, differ: TransactionDiffer())

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

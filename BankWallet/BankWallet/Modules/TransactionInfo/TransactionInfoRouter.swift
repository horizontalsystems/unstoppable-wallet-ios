import UIKit
import ActionSheet

class TransactionInfoRouter {
    weak var viewController: UIViewController?
}

extension TransactionInfoRouter: ITransactionInfoRouter {

    func openFullInfo(transactionHash: String, wallet: Wallet) {
        viewController?.present(FullTransactionInfoRouter.module(transactionHash: transactionHash, wallet: wallet), animated: true)
    }

}

extension TransactionInfoRouter {

    static func module(viewItem: TransactionViewItem) -> ActionSheetController {
        let router = TransactionInfoRouter()

        let interactor = TransactionInfoInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = TransactionInfoPresenter(interactor: interactor, router: router, viewItem: viewItem)
        let viewController = TransactionInfoViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

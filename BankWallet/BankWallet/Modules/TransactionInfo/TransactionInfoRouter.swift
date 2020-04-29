import UIKit
import ActionSheet

class TransactionInfoRouter {
    weak var viewController: UIViewController?
    private weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
    }

}

extension TransactionInfoRouter: ITransactionInfoRouter {

    func showFullInfo(transactionHash: String, wallet: Wallet) {
        let module = FullTransactionInfoRouter.module(transactionHash: transactionHash, wallet: wallet)
        viewController?.dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(module, animated: true)
        }
    }

    func showLockInfo() {
        viewController?.present(InfoRouter.module(title: "lock_info.title".localized, text: "lock_info.text".localized), animated: true)
    }

    func showShare(value: String) {
        let activityViewController = UIActivityViewController(activityItems: [value], applicationActivities: [])
        viewController?.present(activityViewController, animated: true)
    }

    func showDoubleSpendInfo(txHash: String, conflictingTxHash: String?) {
        viewController?.present(DoubleSpendInfoRouter.module(txHash: txHash, conflictingTxHash: conflictingTxHash), animated: true)
    }

}

extension TransactionInfoRouter {

    static func module(viewItem: TransactionViewItem, sourceViewController: UIViewController?) -> UIViewController {
        let router = TransactionInfoRouter(sourceViewController: sourceViewController)
        let interactor = TransactionInfoInteractor(pasteboardManager: App.shared.pasteboardManager)
        let presenter = TransactionInfoPresenter(viewItem: viewItem, interactor: interactor, router: router)
        let viewController = TransactionInfoViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

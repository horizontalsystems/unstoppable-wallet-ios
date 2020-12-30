import UIKit
import ActionSheet
import ThemeKit

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
        let controller = TimeLockInfoRouter.module()
        viewController?.present(ThemeNavigationController(rootViewController: controller), animated: true)
    }

    func showShare(value: String) {
        let activityViewController = UIActivityViewController(activityItems: [value], applicationActivities: [])
        viewController?.present(activityViewController, animated: true)
    }

    func showDoubleSpendInfo(txHash: String, conflictingTxHash: String) {
        viewController?.present(DoubleSpendInfoRouter.module(txHash: txHash, conflictingTxHash: conflictingTxHash), animated: true)
    }

}

extension TransactionInfoRouter {

    static func module(transaction: TransactionRecord, wallet: Wallet, sourceViewController: UIViewController?) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.transactionsAdapter(for: wallet) else {
            return nil
        }

        let router = TransactionInfoRouter(sourceViewController: sourceViewController)
        let interactor = TransactionInfoInteractor(adapter: adapter, rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, feeCoinProvider: App.shared.feeCoinProvider, pasteboardManager: App.shared.pasteboardManager)
        let presenter = TransactionInfoPresenter(transaction: transaction, wallet: wallet, interactor: interactor, router: router)
        let viewController = TransactionInfoViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

import UIKit
import ActionSheet
import ThemeKit
import SafariServices

class TransactionInfoRouter {
    weak var viewController: UIViewController?
    private weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
    }

}

extension TransactionInfoRouter: ITransactionInfoRouter {

    func open(url: String) {
        guard let  url = URL(string: url) else {
            return
        }

        let controller = SFSafariViewController(url: url, configuration: SFSafariViewController.Configuration())

        viewController?.dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(controller, animated: true)
        }
    }

    func showLockInfo() {
        let controller = InfoModule.viewController(dataSource: TimeLockInfoDataSource())
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
        let interactor = TransactionInfoInteractor(adapter: adapter, rateManager: App.shared.rateManager, currencyKit: App.shared.currencyKit, feeCoinProvider: App.shared.feeCoinProvider, pasteboardManager: App.shared.pasteboardManager, appConfigProvider: App.shared.appConfigProvider)
        let presenter = TransactionInfoPresenter(transaction: transaction, wallet: wallet, interactor: interactor, router: router)
        let viewController = TransactionInfoViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

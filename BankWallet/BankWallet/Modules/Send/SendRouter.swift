import UIKit
import ActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {

    func showConfirmation(viewItem: SendConfirmationViewItem, delegate: ISendViewDelegate) {
        let confirmationController = SendConfirmationViewController(delegate: delegate, viewItem: viewItem)
        viewController?.present(confirmationController, animated: true)
    }

    func scanQrCode(delegate: IScanQrCodeDelegate) {
        let scanController = ScanQRController(delegate: delegate)
        viewController?.present(scanController, animated: true)
    }

    func dismiss() {
        viewController?.dismiss(animated: true)
    }

}

extension SendRouter {

    static func module(coinCode: CoinCode) -> UIViewController? {
        guard let adapter = App.shared.adapterManager.adapters.first(where: { $0.wallet.coin.code == coinCode }) else {
            return nil
        }

        let factory = SendConfirmationViewItemFactory()

        let router = SendRouter()
        let interactor = SendInteractor(pasteboardManager: App.shared.pasteboardManager, adapter: adapter, backgroundManager: App.shared.backgroundManager)

        let (amountView, amountModule) = SendAmountRouter.module(coinCode: coinCode, decimal: adapter.decimal)
        let (addressView, addressModule) = SendAddressRouter.module()
        let (feeView, feeModule) = SendFeeRouter.module(coinCode: coinCode, decimal: adapter.decimal)

        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory, amountModule: amountModule, addressModule: addressModule, feeModule: feeModule)
        let viewController = SendViewController(delegate: presenter, views: [amountView, addressView, feeView])

        interactor.delegate = presenter
        presenter.view = viewController

        amountModule.delegate = presenter
        addressModule.delegate = presenter
        feeModule.delegate = presenter

        let navigationController = WalletNavigationController(rootViewController: viewController)
        router.viewController = navigationController
        return navigationController
    }

}

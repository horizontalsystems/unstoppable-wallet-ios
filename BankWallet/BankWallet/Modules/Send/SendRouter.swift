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

    func scanQrCode(onCodeParse: ((String) -> ())?) {
        let scanController = ScanQRController()
        scanController.onCodeParse = onCodeParse
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

        let interactorState = SendInteractorState(adapter: adapter)
        let factory = SendStateViewItemFactory()
        let userInput = SendUserInput()

        let router = SendRouter()
        let interactor = SendInteractor(currencyManager: App.shared.currencyManager, rateStorage: App.shared.grdbStorage, localStorage: App.shared.localStorage, pasteboardManager: App.shared.pasteboardManager, state: interactorState, appConfigProvider: App.shared.appConfigProvider, backgroundManager: App.shared.backgroundManager)

        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory, userInput: userInput)
        let viewController = SendNewViewController(delegate: presenter)

        presenter.amountModule = SendAmountModule(adapter: adapter, appConfigProvider: App.shared.appConfigProvider, localStorage: App.shared.localStorage, rateStorage: App.shared.grdbStorage, currencyManager: App.shared.currencyManager, delegate: presenter)
        presenter.addressModule = SendAddressModule(viewController: viewController, adapter: adapter, delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController

        let navigationController = WalletNavigationController(rootViewController: viewController)
        router.viewController = navigationController
        return navigationController
    }

}

import UIKit
import GrouviActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {
}

extension SendRouter {

    static func module(coinCode: CoinCode) -> ActionSheetController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coinCode == coinCode }) else {
            return nil
        }

        let interactorState = SendInteractorState(wallet: wallet)
        let factory = SendStateViewItemFactory()
        let userInput = SendUserInput()

        let router = SendRouter()
        let interactor = SendInteractor(currencyManager: App.shared.currencyManager, rateStorage: App.shared.grdbStorage, localStorage: App.shared.localStorage, pasteboardManager: App.shared.pasteboardManager, state: interactorState)
        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory, userInput: userInput)
        let view = SendAlertModel(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        let viewController = ActionSheetController(withModel: view, actionSheetThemeConfig: AppTheme.actionSheetConfig)
        viewController.backgroundColor = .crypto_Dark_Bars
        router.viewController = viewController

        view.onScanClicked = { [weak view, weak viewController] in
            let scanController = ScanQRController()
            scanController.onCodeParse = { address in
                view?.onScan(address: address)
            }
            viewController?.present(scanController, animated: true)
        }

        view.onShowConfirmation = {  [weak view, weak viewController] viewItem in
            let model = SendConfirmationAlertModel(viewItem: viewItem)

            model.onCopyAddress = {
                view?.onCopyAddress?()
            }

            let confirmationController = ActionSheetController(withModel: model, actionSheetThemeConfig: SendTheme.confirmationSheetConfig)
            confirmationController.backgroundColor = .crypto_Dark_Bars

            confirmationController.onDismiss = { success in
                if success {
                    view?.onConfirm()
                }
            }

            viewController?.present(confirmationController, animated: true)
        }

        return viewController
    }

}

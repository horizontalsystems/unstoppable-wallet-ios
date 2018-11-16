import UIKit
import GrouviActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {

    func startScan(result: @escaping ((String) -> ())) {
        let scanController = ScanQRController()
        scanController.onCodeParse = result
        viewController?.present(scanController, animated: true)
    }

}

extension SendRouter {

    static func module(coin: Coin) -> ActionSheetController? {
        guard let wallet = App.shared.walletManager.wallets.first(where: { $0.coin == coin }) else {
            return nil
        }

        let factory = SendStateViewItemFactory()
        let userInput = SendUserInput()

        let router = SendRouter()
        let interactor = SendInteractor(currencyManager: App.shared.currencyManager, rateManager: App.shared.rateManager, pasteboardManager: App.shared.pasteboardManager, wallet: wallet)
        let presenter = SendPresenter(interactor: interactor, router: router, factory: factory, userInput: userInput)
        let view = SendAlertModel(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view

        let viewController = ActionSheetController(withModel: view, actionStyle: .sheet(showDismiss: false))
        viewController.backgroundColor = .cryptoBarsColor
        router.viewController = viewController

        view.onScanClicked = {
            let scanController = ScanQRController()
            scanController.onCodeParse = { address in
                view.onScan(address: address)
            }
            viewController.present(scanController, animated: true)
        }

        return viewController
    }

}

import UIKit
import WalletKit
import GrouviActionSheet

class SendRouter {
    weak var viewController: UIViewController?
    weak var view: ISendView?
}

extension SendRouter: ISendRouter {

    func startScan(result: @escaping ((String) -> ())) {
        let scanController = ScanQRController()
        scanController.onCodeParse = result
        viewController?.present(scanController, animated: true)
    }

}

extension SendRouter {

    static func module(coin: Coin) -> ActionSheetController {
        let router = SendRouter()
        let interactor = SendInteractor(storage: RealmStorage.shared, coin: coin)
        let presenter = SendPresenter(interactor: interactor, router: router, coinCode: coin.code)
        interactor.delegate = presenter

        let sendAlertModel = SendAlertModel(viewDelegate: presenter, coin: coin)
        router.view = sendAlertModel
        presenter.view = sendAlertModel
        
        let viewController = ActionSheetController(withModel: sendAlertModel, actionStyle: .sheet(showDismiss: false))
        viewController.backgroundColor = .cryptoBarsColor
        router.viewController = viewController

        return viewController
    }

}

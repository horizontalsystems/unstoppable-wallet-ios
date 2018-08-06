import UIKit
import WalletKit
import GrouviActionSheet

class SendRouter {
    weak var viewController: UIViewController?
}

extension SendRouter: ISendRouter {

    func startScan() {
        print("start scan")
    }

}

extension SendRouter {

    static func module(coin: Coin) -> ActionSheetController {
        let router = SendRouter()
        let interactor = SendInteractor(storage: WalletKitProvider.shared.storage, coin: coin)
        let presenter = SendPresenter(interactor: interactor, router: router, coinCode: coin.code)
        interactor.delegate = presenter

        let sendAlertModel = SendAlertModel(viewDelegate: presenter, coin: coin)
        presenter.view = sendAlertModel
        
        let viewController = ActionSheetController(withModel: sendAlertModel, actionStyle: .sheet(showDismiss: false))
        viewController.backgroundColor = .cryptoBarsColor
        router.viewController = viewController

        return viewController
    }

}

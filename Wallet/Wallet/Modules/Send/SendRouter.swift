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

    static func module(coins: [Coin]) -> ActionSheetController {
        let router = SendRouter()
        let interactor = SendInteractor(coins: coins)
        let presenter = SendPresenter(interactor: interactor, router: router)
        let sendAlertModel = SendAlertModel(viewDelegate: presenter)
        let viewController = ActionSheetController(withModel: sendAlertModel, actionStyle: .sheet(showDismiss: false))

        interactor.delegate = presenter
        presenter.view = sendAlertModel
        router.viewController = viewController

        return viewController
    }

}

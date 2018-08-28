import UIKit
import GrouviActionSheet

class DepositRouter {
    weak var viewController: UIViewController?
}

extension DepositRouter: IDepositRouter {
}

extension DepositRouter {

    static func module(adapterId: String?) -> ActionSheetController {
        let adapters = AdapterManager.shared.adapters.filter { adapterId == nil || adapterId == $0.id }

        let router = DepositRouter()
        let interactor = DepositInteractor(adapters: adapters)
        let presenter = DepositPresenter(interactor: interactor, router: router)
        let depositAlertModel = DepositAlertModel(viewDelegate: presenter, adapters: adapters)

        let viewController = ActionSheetController(withModel: depositAlertModel, actionStyle: .sheet(showDismiss: false))
        viewController.backgroundColor = .cryptoBarsColor

        interactor.delegate = presenter
        presenter.view = depositAlertModel
        router.viewController = viewController

        return viewController
    }

}

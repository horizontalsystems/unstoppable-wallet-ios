import UIKit

class ExperimentalFeaturesRouter {
    weak var viewController: UIViewController?
}

extension ExperimentalFeaturesRouter: IExperimentalFeaturesRouter {

    func showBitcoinHodling() {
        viewController?.navigationController?.pushViewController(ManageAccountsRouter.module(mode: .pushed), animated: true)
    }

}

extension ExperimentalFeaturesRouter {

    static func module() -> UIViewController {
        let router = ExperimentalFeaturesRouter()
        let interactor = ExperimentalFeaturesInteractor()
        let presenter = ExperimentalFeaturesPresenter(router: router, interactor: interactor)
        let view = ExperimentalFeaturesViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = view
        router.viewController = view

        return view
    }

}

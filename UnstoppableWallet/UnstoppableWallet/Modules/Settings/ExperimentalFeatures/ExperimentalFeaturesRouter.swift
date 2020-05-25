import UIKit

class ExperimentalFeaturesRouter {
    weak var viewController: UIViewController?
}

extension ExperimentalFeaturesRouter: IExperimentalFeaturesRouter {

    func showBitcoinHodling() {
        viewController?.navigationController?.pushViewController(BitcoinHodlingRouter.module(), animated: true)
    }

}

extension ExperimentalFeaturesRouter {

    static func module() -> UIViewController {
        let router = ExperimentalFeaturesRouter()
        let presenter = ExperimentalFeaturesPresenter(router: router)
        let view = ExperimentalFeaturesViewController(delegate: presenter)

        router.viewController = view

        return view
    }

}

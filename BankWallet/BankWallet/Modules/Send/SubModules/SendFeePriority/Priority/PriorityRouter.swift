import UIKit

class PriorityRouter {
    weak var viewController: UIViewController?
    weak var priorityDelegate: IPriorityDelegate?

}

extension PriorityRouter: IPriorityRouter {

    func dismiss(with priority: FeeRatePriority) {
        priorityDelegate?.onSelect(priority: priority)
        viewController?.dismiss(animated: true)
    }

}

extension PriorityRouter {

    static func module(priorityDelegate: IPriorityDelegate?, coin: Coin, priority: FeeRatePriority) -> UIViewController? {
        guard let feeRateProvider = App.shared.feeRateProviderFactory.provider(coin: coin) else {
            return nil
        }


        let router = PriorityRouter()
        let interactor = PriorityInteractor(feeRateProvider: feeRateProvider)
        let presenter = PriorityPresenter(router: router, interactor: interactor, priority: priority)
        let viewController = AlertViewController(delegate: presenter)

        presenter.view = viewController

        router.viewController = viewController
        router.priorityDelegate = priorityDelegate

        return viewController
    }

}

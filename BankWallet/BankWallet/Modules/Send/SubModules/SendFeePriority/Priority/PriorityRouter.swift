import UIKit

class PriorityRouter {
    weak var viewController: UIViewController?
    weak var priorityDelegate: IPriorityDelegate?

}

extension PriorityRouter: IPriorityRouter {

    func dismiss(with priority: FeeRatePriority) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.priorityDelegate?.onSelect(priority: priority)
        }
    }

}

extension PriorityRouter {

    static func module(priorityDelegate: IPriorityDelegate?, priority: FeeRatePriority) -> UIViewController {
        let router = PriorityRouter()
        let presenter = PriorityPresenter(router: router, priority: priority)
        let viewController = AlertViewController(delegate: presenter)

        presenter.view = viewController

        router.viewController = viewController
        router.priorityDelegate = priorityDelegate

        return viewController
    }

}

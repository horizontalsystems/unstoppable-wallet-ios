import UIKit

protocol ISortTypeDelegate: class {
    func onSelect(sort: BalanceSortType)
}

class SortTypeRouter {
    weak var viewController: UIViewController?
    weak var sortTypeDelegate: ISortTypeDelegate?

}

extension SortTypeRouter: ISortTypeRouter {

    func dismiss(with sort: BalanceSortType) {
        viewController?.dismiss(animated: true) { [weak self] in
            self?.sortTypeDelegate?.onSelect(sort: sort)
        }
    }

}

extension SortTypeRouter {

    static func module(sortTypeDelegate: ISortTypeDelegate?, sort: BalanceSortType) -> UIViewController {
        let router = SortTypeRouter()
        let interactor = SortTypeInteractor(localStorage: UserDefaultsStorage.shared)
        let presenter = SortTypePresenter(router: router, interactor: interactor, sort: sort)
        let viewController = AlertViewController(delegate: presenter)

        interactor.delegate = presenter

        router.viewController = viewController
        router.sortTypeDelegate = sortTypeDelegate

        return viewController
    }

}

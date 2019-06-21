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
        let interactor = SortTypeInteractor(localStorage: App.shared.localStorage)
        let presenter = SortTypePresenter(router: router, interactor: interactor, sort: sort)
        let viewController = SortTypeViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        presenter.onDidLoad()

        router.viewController = viewController
        router.sortTypeDelegate = sortTypeDelegate

        return viewController
    }

}

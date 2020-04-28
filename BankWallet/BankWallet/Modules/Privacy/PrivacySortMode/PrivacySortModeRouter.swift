import UIKit

class PrivacySortModeRouter {
    weak var viewController: UIViewController?
}

extension PrivacySortModeRouter: IPrivacySortModeRouter {

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension PrivacySortModeRouter {

    static func module(currentSortMode: TransactionDataSortMode, delegate: IPrivacySortModeDelegate) -> UIViewController {
        let router = PrivacySortModeRouter()
        let presenter = PrivacySortModePresenter(currentSortMode: currentSortMode, router: router)
        let viewController = PrivacySortModeViewController(delegate: presenter)

        presenter.view = viewController
        presenter.delegate = delegate
        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

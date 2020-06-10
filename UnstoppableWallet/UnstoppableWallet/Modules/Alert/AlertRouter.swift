import UIKit

class AlertRouter {
    weak var viewController: UIViewController?
}

extension AlertRouter: IAlertRouter {

    func close() {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.dismiss(animated: true)
        }
    }

}

extension AlertRouter {

    static func module(title: String, viewItems: [AlertViewItem], onSelect: @escaping (Int) -> ()) -> UIViewController {
        let router = AlertRouter()
        let presenter = AlertPresenter(viewItems: viewItems, onSelect: onSelect, router: router)
        let viewController = AlertViewController(alertTitle: title, delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toAlert
    }

}

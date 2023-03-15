import UIKit

class AlertRouter {
    weak var viewController: UIViewController?
}

extension AlertRouter: IAlertRouter {

    func close(completion: (() -> Void)? = nil) {
        DispatchQueue.main.async { [weak self] in
            self?.viewController?.dismiss(animated: true, completion: completion)
        }
    }

}

extension AlertRouter {

    static func module(title: String, viewItems: [AlertViewItem], afterClose: Bool = false, onSelect: @escaping (Int) -> ()) -> UIViewController {
        let router = AlertRouter()
        let presenter = AlertPresenter(viewItems: viewItems, onSelect: onSelect, router: router, afterClose: afterClose)
        let viewController = AlertViewController(alertTitle: title, delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        return viewController.toAlert
    }

}

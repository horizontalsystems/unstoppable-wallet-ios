import UIKit
import ThemeKit

class AddTokenRouter {
    weak var viewController: UIViewController?
    weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
    }

}

extension AddTokenRouter: IAddTokenRouter {

    func closeAndShowAddErc20Token() {
        let module = AddErc20TokenRouter.module()

        viewController?.dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(module, animated: true)
        }

    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension AddTokenRouter {

    static func module(sourceViewController: UIViewController?) -> UIViewController {
        let router = AddTokenRouter(sourceViewController: sourceViewController)
        let presenter = AddTokenPresenter(router: router)
        let viewController = AddTokenViewController(delegate: presenter)

        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

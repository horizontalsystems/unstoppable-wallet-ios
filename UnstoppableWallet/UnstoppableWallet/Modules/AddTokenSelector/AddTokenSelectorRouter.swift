import UIKit
import ThemeKit

class AddTokenSelectorRouter {
    weak var viewController: UIViewController?
    weak var sourceViewController: UIViewController?

    init(sourceViewController: UIViewController?) {
        self.sourceViewController = sourceViewController
    }

}

extension AddTokenSelectorRouter: IAddTokenSelectorRouter {

    func closeAndShowAddErc20Token() {
        guard let module = AddErc20TokenModule.viewController() else {
            return
        }

        viewController?.dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(module, animated: true)
        }
    }

    func closeAndShowAddBep20Token() {
        guard let module = AddBep20TokenModule.viewController() else {
            return
        }

        viewController?.dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(module, animated: true)
        }
    }

    func closeAndShowAddBep2Token() {
        guard let module = AddBep2TokenModule.viewController() else {
            return
        }

        viewController?.dismiss(animated: true) { [weak self] in
            self?.sourceViewController?.present(module, animated: true)
        }
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension AddTokenSelectorRouter {

    static func module(sourceViewController: UIViewController?) -> UIViewController {
        let router = AddTokenSelectorRouter(sourceViewController: sourceViewController)
        let presenter = AddTokenSelectorPresenter(router: router)
        let viewController = AddTokenSelectorViewController(delegate: presenter)

        router.viewController = viewController

        return viewController.toBottomSheet
    }

}

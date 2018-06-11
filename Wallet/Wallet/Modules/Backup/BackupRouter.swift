import Foundation

class BackupRouter {
    enum DismissMode {
        case toMain
        case dismissSelf
    }

    weak var navigationController: UINavigationController?

    let dismissMode: DismissMode

    init(dismissMode: DismissMode) {
        self.dismissMode = dismissMode
    }
}

extension BackupRouter: BackupRouterProtocol {

    func close() {
        switch dismissMode {
        case .toMain:
          navigateToMain()
        case .dismissSelf:
            navigationController?.dismiss(animated: true)
        }
    }

    private func navigateToMain() {
        navigationController?.topViewController?.view.endEditing(true)

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let viewController = MainRouter.module()

        UIView.transition(with: window, duration: 0.5, options: .transitionCrossDissolve, animations: {
            window.rootViewController = viewController
        })
    }

}

extension BackupRouter {

    static func module(dismissMode: DismissMode) -> UIViewController {
        let router = BackupRouter(dismissMode: dismissMode)
        let interactor = BackupInteractor(walletDataProvider: Factory.instance.stubWalletDataProvider, indexesProvider: Factory.instance.randomGenerator)
        let presenter = BackupPresenter(delegate: interactor, router: router)
        let navigationController = BackupNavigationController(viewDelegate: presenter)

        interactor.presenter = presenter
        presenter.view = navigationController
        router.navigationController = navigationController

        return navigationController
    }

}

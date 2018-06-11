import Foundation

class BackupRouter {
    enum DismissMode {
        case toMain
        case dismissSelf
    }

    weak var viewController: UIViewController?

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
            viewController?.dismiss(animated: true)
        }
    }

    private func navigateToMain() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        let viewController = MainRouter.viewController

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
        let viewController = BackupNavigationController(viewDelegate: presenter)

        interactor.presenter = presenter
        presenter.view = viewController
        router.viewController = viewController

        return viewController
    }

}

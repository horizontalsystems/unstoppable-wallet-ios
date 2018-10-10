import UIKit

class BackupRouter {
    weak var navigationController: UINavigationController?
}

extension BackupRouter: IBackupRouter {


    func close() {
        navigationController?.dismiss(animated: true)
    }

    func navigateToMain() {
        navigationController?.topViewController?.view.endEditing(true)

        guard let window = UIApplication.shared.keyWindow else {
            return
        }

        LaunchRouter.presenter(window: window, replace: true).launch(shouldLock: true)
    }

}

extension BackupRouter {

    static func module(dismissMode: BackupPresenter.DismissMode) -> UIViewController {
        let router = BackupRouter()
        let interactor = BackupInteractor(walletManager: App.shared.wordsManager, indexesProvider: Factory.instance.randomProvider)
        let presenter = BackupPresenter(interactor: interactor, router: router, dismissMode: dismissMode)
        let navigationController = BackupNavigationController(viewDelegate: presenter)

        interactor.delegate = presenter
        presenter.view = navigationController
        router.navigationController = navigationController

        return navigationController
    }

}

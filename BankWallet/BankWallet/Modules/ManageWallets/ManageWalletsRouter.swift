import UIKit
import ThemeKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?

    weak var navigationController: UINavigationController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showSettings(delegate: IBlockchainSettingsDelegate) {
        navigationController?.pushViewController(BlockchainSettingsRouter.module(proceedMode: .restore, delegate: delegate), animated: true)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate) {
        let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .presented, delegate: delegate)
        let controller = ThemeNavigationController(rootViewController: module)
        navigationController = controller
        viewController?.present(controller, animated: true)
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

    func closePresented() {
        navigationController?.dismiss(animated: true)
    }

}

extension ManageWalletsRouter {

    static func module(presentationMode: ManageWalletsModule.PresentationMode) -> UIViewController {
        let router = ManageWalletsRouter()
        let interactor = ManageWalletsInteractor(
                appConfigProvider: App.shared.appConfigProvider,
                walletManager: App.shared.walletManager,
                walletFactory: App.shared.walletFactory,
                accountManager: App.shared.accountManager,
                accountCreator: App.shared.accountCreator,
                predefinedAccountTypeManager: App.shared.predefinedAccountTypeManager,
                coinSettingsManager: App.shared.coinSettingsManager
        )
        let presenter = ManageWalletsPresenter(presentationMode: presentationMode, interactor: interactor, router: router)
        let viewController = ManageWalletsViewController(delegate: presenter)

        interactor.delegate = presenter
        presenter.view = viewController
        router.viewController = viewController

        switch presentationMode {
        case .presented: return ThemeNavigationController(rootViewController: viewController)
        case .pushed: return viewController
        }
    }

}

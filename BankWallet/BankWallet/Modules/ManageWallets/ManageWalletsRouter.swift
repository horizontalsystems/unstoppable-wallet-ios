import UIKit
import ThemeKit

class ManageWalletsRouter {
    weak var viewController: UIViewController?

    weak var navigationController: UINavigationController?
}

extension ManageWalletsRouter: IManageWalletsRouter {

    func showSettings(coin: Coin, delegate: IDerivationSettingsDelegate) {
        let module = DerivationSettingsRouter.module(proceedMode: .done, canSave: false, activeCoins: [coin], showOnlyCoin: coin, delegate: delegate)
        viewController?.navigationController?.pushViewController(module, animated: true)
    }

    func showRestore(predefinedAccountType: PredefinedAccountType, delegate: ICredentialsCheckDelegate) {
        let module = RestoreRouter.module(predefinedAccountType: predefinedAccountType, mode: .presented, proceedMode: .restore, delegate: delegate)
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

    func closePushed() {
        viewController?.navigationController?.popViewController(animated: true)
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
                derivationSettingsManager: App.shared.derivationSettingsManager
        )
        let presenter = ManageWalletsPresenter(presentationMode: presentationMode, interactor: interactor, router: router)
        let viewController = ManageWalletsViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        switch presentationMode {
        case .presented: return ThemeNavigationController(rootViewController: viewController)
        case .pushed: return viewController
        }
    }

}

import UIKit
import ThemeKit

class CreateWalletRouter {
    weak var viewController: UIViewController?
}

extension CreateWalletRouter: ICreateWalletRouter {

    func showMain() {
        UIApplication.shared.keyWindow?.set(newRootController: MainRouter.module(selectedTab: .balance))
    }

    func close() {
        viewController?.dismiss(animated: true)
    }

}

extension CreateWalletRouter {

    static func module(presentationMode: CreateWalletModule.PresentationMode, predefinedAccountType: PredefinedAccountType? = nil) -> UIViewController {
        let router = CreateWalletRouter()
        let interactor = CreateWalletInteractor(
                appConfigProvider: App.shared.appConfigProvider,
                accountCreator: App.shared.accountCreator,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                coinSettingsManager: App.shared.coinSettingsManager
        )
        let presenter = CreateWalletPresenter(presentationMode: presentationMode, predefinedAccountType: predefinedAccountType, interactor: interactor, router: router)
        let viewController = CreateWalletViewController(delegate: presenter)

        presenter.view = viewController
        router.viewController = viewController

        switch presentationMode {
        case .initial: return viewController
        case .inApp: return ThemeNavigationController(rootViewController: viewController)
        }
    }

}

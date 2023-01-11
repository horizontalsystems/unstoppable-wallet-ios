import UIKit
import ThemeKit
import LanguageKit

struct CreateAccountModule {

    static func viewController(advanced: Bool = false, sourceViewController: UIViewController? = nil, listener: ICreateAccountListener? = nil) -> UIViewController {
        let service = CreateAccountService(
                accountFactory: App.shared.accountFactory,
                predefinedBlockchainService: App.shared.predefinedBlockchainService,
                languageManager: LanguageManager.shared,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                marketKit: App.shared.marketKit
        )
        let viewModel = CreateAccountViewModel(service: service)

        if advanced {
            return CreateAccountAdvancedViewController(viewModel: viewModel, listener: listener)
        } else {
            let viewController = CreateAccountSimpleViewController(viewModel: viewModel, listener: listener)

            let module = ThemeNavigationController(rootViewController: viewController)

            if App.shared.termsManager.termsAccepted {
                return module
            } else {
                return TermsModule.viewController(sourceViewController: sourceViewController, moduleToOpen: module)
            }
        }
    }

}

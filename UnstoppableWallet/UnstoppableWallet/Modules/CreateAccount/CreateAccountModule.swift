
import UIKit

enum CreateAccountModule {
    static func viewController(advanced: Bool = false, sourceViewController: UIViewController? = nil, listener: ICreateAccountListener? = nil) -> UIViewController {
        let service = CreateAccountService(
            accountFactory: Core.shared.accountFactory,
            predefinedBlockchainService: Core.shared.predefinedBlockchainService,
            languageManager: LanguageManager.shared,
            accountManager: Core.shared.accountManager,
            walletManager: Core.shared.walletManager,
            marketKit: Core.shared.marketKit
        )
        let viewModel = CreateAccountViewModel(service: service)

        if advanced {
            return CreateAccountAdvancedViewController(viewModel: viewModel, listener: listener)
        } else {
            let viewController = CreateAccountSimpleViewController(viewModel: viewModel, listener: listener)

            let module = ThemeNavigationController(rootViewController: viewController)

            if Core.shared.termsManager.termsAccepted {
                return module
            } else {
                return TermsModule.viewController(sourceViewController: sourceViewController, moduleToOpen: module)
            }
        }
    }
}

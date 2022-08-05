import UIKit
import ThemeKit

struct CreateAccountModule {

    static func viewController() -> UIViewController {
        let service = CreateAccountService(
                accountFactory: App.shared.accountFactory,
                predefinedBlockchainService: App.shared.predefinedBlockchainService,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                passphraseValidator: PassphraseValidator(),
                marketKit: App.shared.marketKit
        )
        let viewModel = CreateAccountViewModel(service: service)
        let viewController = CreateAccountViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

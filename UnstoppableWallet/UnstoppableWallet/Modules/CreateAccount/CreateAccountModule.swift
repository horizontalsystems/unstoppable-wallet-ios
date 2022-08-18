import UIKit
import ThemeKit
import LanguageKit

struct CreateAccountModule {

    static func viewController(listener: ICreateAccountListener? = nil) -> UIViewController {
        let service = CreateAccountService(
                accountFactory: App.shared.accountFactory,
                predefinedBlockchainService: App.shared.predefinedBlockchainService,
                languageManager: LanguageManager.shared,
                accountManager: App.shared.accountManager,
                walletManager: App.shared.walletManager,
                passphraseValidator: PassphraseValidator(),
                marketKit: App.shared.marketKit
        )
        let viewModel = CreateAccountViewModel(service: service)
        let viewController = CreateAccountViewController(viewModel: viewModel, listener: listener)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

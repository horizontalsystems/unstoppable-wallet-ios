import UIKit
import ThemeKit
import LanguageKit

struct RestoreModule {

    static func viewController(advanced: Bool = false, sourceViewController: UIViewController? = nil, returnViewController: UIViewController? = nil, viaPush: Bool = false) -> UIViewController {
        let mnemonicService = RestoreMnemonicService(languageManager: LanguageManager.shared)
        let mnemonicViewModel = RestoreMnemonicViewModel(service: mnemonicService)

        let privateKeyService = RestorePrivateKeyService()
        let privateKeyViewModel = RestorePrivateKeyViewModel(service: privateKeyService)

        let service = RestoreService(accountFactory: App.shared.accountFactory)
        let viewModel = RestoreViewModel(service: service, mnemonicViewModel: mnemonicViewModel, privateKeyViewModel: privateKeyViewModel)

        let viewController = RestoreViewController(
                advanced: advanced,
                viewModel: viewModel,
                mnemonicViewModel: mnemonicViewModel,
                privateKeyViewModel: privateKeyViewModel,
                returnViewController: returnViewController
        )

        if advanced {
            return viewController
        } else {
            let module = viaPush ? viewController : ThemeNavigationController(rootViewController: viewController)

            if App.shared.termsManager.termsAccepted {
                return module
            } else {
                return TermsModule.viewController(sourceViewController: sourceViewController, moduleToOpen: module)
            }
        }
    }

}

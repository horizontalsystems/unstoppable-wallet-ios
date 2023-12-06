import ThemeKit
import UIKit

enum RestoreNonStandardModule {
    static func viewController(sourceViewController _: UIViewController?, returnViewController: UIViewController? = nil) -> UIViewController {
        let mnemonicService = RestoreMnemonicNonStandardService(languageManager: LanguageManager.shared)
        let mnemonicViewModel = RestoreMnemonicNonStandardViewModel(service: mnemonicService)

        let service = RestoreService(accountFactory: App.shared.accountFactory)
        let viewModel = RestoreNonStandardViewModel(service: service, mnemonicViewModel: mnemonicViewModel)

        let viewController = RestoreNonStandardViewController(
            viewModel: viewModel,
            mnemonicViewModel: mnemonicViewModel,
            returnViewController: returnViewController
        )

        return viewController
    }
}

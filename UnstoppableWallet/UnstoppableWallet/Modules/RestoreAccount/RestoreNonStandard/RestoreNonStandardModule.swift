import UIKit
import ThemeKit
import LanguageKit

struct RestoreNonStandardModule {

    static func viewController(sourceViewController: UIViewController?, returnViewController: UIViewController? = nil) -> UIViewController {
        let mnemonicService = RestoreMnemonicNonStandardService(languageManager: LanguageManager.shared)
        let mnemonicViewModel = RestoreMnemonicNonStandardViewModel(service: mnemonicService)

        let viewModel = RestoreNonStandardViewModel(mnemonicViewModel: mnemonicViewModel)

        let viewController = RestoreNonStandardViewController(
                viewModel: viewModel,
                mnemonicViewModel: mnemonicViewModel,
                returnViewController: returnViewController
        )

        return viewController
    }

}

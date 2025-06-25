
import UIKit

enum RestoreNonStandardModule {
    static func viewController(onRestore: @escaping () -> Void) -> UIViewController {
        let mnemonicService = RestoreMnemonicNonStandardService(languageManager: LanguageManager.shared)
        let mnemonicViewModel = RestoreMnemonicNonStandardViewModel(service: mnemonicService)

        let service = RestoreService(accountFactory: Core.shared.accountFactory)
        let viewModel = RestoreNonStandardViewModel(service: service, mnemonicViewModel: mnemonicViewModel)

        let viewController = RestoreNonStandardViewController(
            viewModel: viewModel,
            mnemonicViewModel: mnemonicViewModel,
            onRestore: onRestore
        )

        return viewController
    }
}

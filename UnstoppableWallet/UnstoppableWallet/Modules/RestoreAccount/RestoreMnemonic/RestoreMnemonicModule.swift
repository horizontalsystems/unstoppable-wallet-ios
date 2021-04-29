import UIKit
import ThemeKit

struct RestoreMnemonicModule {

    static func viewController() -> UIViewController {
        let service = RestoreMnemonicService(wordsManager: App.shared.wordsManager, passphraseValidator: PassphraseValidator())
        let viewModel = RestoreMnemonicViewModel(service: service)
        let viewController = RestoreMnemonicViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

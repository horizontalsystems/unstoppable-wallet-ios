import UIKit
import ThemeKit

struct RestoreMnemonicModule {

    static func viewController(sourceViewController: UIViewController? = nil) -> UIViewController {
        let service = RestoreMnemonicService(accountFactory: App.shared.accountFactory, passphraseValidator: PassphraseValidator())
        let viewModel = RestoreMnemonicViewModel(service: service)
        let viewController = RestoreMnemonicViewController(viewModel: viewModel, sourceViewController: sourceViewController)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

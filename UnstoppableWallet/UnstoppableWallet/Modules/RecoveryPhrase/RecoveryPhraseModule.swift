import UIKit
import ThemeKit

struct RecoveryPhraseModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = RecoveryPhraseService(account: account) else {
            return nil
        }

        let viewModel = RecoveryPhraseViewModel(service: service)
        let viewController = RecoveryPhraseViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

import UIKit
import ThemeKit

struct ShowKeyModule {

    static func viewController(account: Account) -> UIViewController? {
        guard let service = ShowKeyService(
                account: account,
                pinKit: App.shared.pinKit,
                ethereumKitManager: App.shared.ethereumKitManager
        ) else {
            return nil
        }
        let viewModel = ShowKeyViewModel(service: service)
        let viewController = ShowKeyViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

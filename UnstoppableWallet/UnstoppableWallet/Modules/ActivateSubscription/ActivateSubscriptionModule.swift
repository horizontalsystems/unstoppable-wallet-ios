import Foundation

import UIKit

enum ActivateSubscriptionModule {
    static func viewController() -> UIViewController {
        let service = ActivateSubscriptionService(
            marketKit: Core.shared.marketKit,
            subscriptionManager: Core.shared.subscriptionManager,
            accountManager: Core.shared.accountManager
        )

        let viewModel = ActivateSubscriptionViewModel(service: service)
        let viewController = ActivateSubscriptionViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

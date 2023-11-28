import Foundation
import ThemeKit
import UIKit

struct ActivateSubscriptionModule {
    static func viewController() -> UIViewController {
        let service = ActivateSubscriptionService(
            marketKit: App.shared.marketKit,
            subscriptionManager: App.shared.subscriptionManager,
            accountManager: App.shared.accountManager
        )

        let viewModel = ActivateSubscriptionViewModel(service: service)
        let viewController = ActivateSubscriptionViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }
}

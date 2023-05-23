import Foundation
import UIKit
import ThemeKit

struct ActivateSubscriptionModule {

    static func viewController(address: String) -> UIViewController? {
        guard let service = ActivateSubscriptionService(
                address: address,
                marketKit: App.shared.marketKit,
                subscriptionManager: App.shared.subscriptionManager,
                accountManager: App.shared.accountManager
        ) else {
            return nil
        }

        let viewModel = ActivateSubscriptionViewModel(service: service)
        let viewController = ActivateSubscriptionViewController(viewModel: viewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

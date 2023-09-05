import SwiftUI
import UIKit

struct SimpleActivateModule {

    static var bitcoinHodlingViewController: UIViewController {
        let viewModel = SimpleActivateViewModel(localStorage: App.shared.localStorage)

        let view = SimpleActivateView(
                viewModel: viewModel,
                toggleText: "settings.bitcoin_hodling.lock_time".localized,
                description: "settings.bitcoin_hodling.description".localized(AppConfig.appName, AppConfig.appName)
        )

        let viewController = UIHostingController(rootView: view)
        viewController.title = "settings.bitcoin_hodling.title".localized

        return viewController
    }

}

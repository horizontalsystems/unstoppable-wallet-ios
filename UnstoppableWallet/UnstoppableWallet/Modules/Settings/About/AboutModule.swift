import UIKit

struct AboutModule {

    static func viewController() -> UIViewController {
        let service = AboutService(
                termsManager: App.shared.termsManager,
                systemInfoManager: App.shared.systemInfoManager,
                appConfigProvider: App.shared.appConfigProvider,
                rateAppManager: App.shared.rateAppManager
        )

        let viewModel = AboutViewModel(service: service)

        return AboutViewController(viewModel: viewModel)
    }

}

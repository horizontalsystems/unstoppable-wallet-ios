import UIKit

struct LaunchScreenModule {

    static func viewController() -> UIViewController {
        let service = LaunchScreenService(launchScreenManager: App.shared.launchScreenManager)
        let viewModel = LaunchScreenViewModel(service: service)
        return LaunchScreenViewController(viewModel: viewModel)
    }

}

import UIKit

struct ExperimentalFeaturesModule {

    static func viewController() -> UIViewController {
        let service = ExperimentalFeaturesService(testNetManager: App.shared.testNetManager)
        let viewModel = ExperimentalFeaturesViewModel(service: service)
        return ExperimentalFeaturesViewController(viewModel: viewModel)
    }

}

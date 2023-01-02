import UIKit

struct SecurityModule {

    static func viewController() -> UIViewController {
        let service = SecurityService(pinKit: App.shared.pinKit)
        let viewModel = SecurityViewModel(service: service)
        return SecurityViewController(viewModel: viewModel)
    }

}

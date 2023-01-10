import UIKit

struct SecuritySettingsModule {

    static func viewController() -> UIViewController {
        let service = SecuritySettingsService(pinKit: App.shared.pinKit)
        let viewModel = SecuritySettingsViewModel(service: service)
        return SecuritySettingsViewController(viewModel: viewModel)
    }

}

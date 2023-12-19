import UIKit

enum ContactBookSettingsModule {
    static var viewController: UIViewController? {
        let service = ContactBookSettingsService(contactManager: App.shared.contactManager)
        let viewModel = ContactBookSettingsViewModel(service: service)
        return ContactBookSettingsViewController(viewModel: viewModel)
    }
}

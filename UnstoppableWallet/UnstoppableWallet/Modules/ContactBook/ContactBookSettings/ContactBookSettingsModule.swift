import UIKit

class ContactBookSettingsModule {

    static var viewController: UIViewController? {
        guard let manager = App.shared.contactManager else {
            return nil
        }
        let service = ContactBookSettingsService(contactManager: manager)
        let viewModel = ContactBookSettingsViewModel(service: service)
        return ContactBookSettingsViewController(viewModel: viewModel)
    }

}

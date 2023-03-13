import UIKit

class ContactBookSyncSettingsModule {

    static var viewController: UIViewController? {
        guard let manager = App.shared.contactManager else {
            return nil
        }
        let service = ContactBookSyncSettingsService(contactManager: manager)
        let viewModel = ContactBookSyncSettingsViewModel(service: service)
        return ContactBookSyncSettingsViewController(viewModel: viewModel)
    }

}

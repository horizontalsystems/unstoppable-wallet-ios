import UIKit

class AddressBookSyncSettingsModule {

    static var viewController: UIViewController? {
        guard let manager = App.shared.contactManager else {
            return nil
        }
        let service = AddressBookSyncSettingsService(contactManager: manager)
        let viewModel = AddressBookSyncSettingsViewModel(service: service)
        return AddressBookSyncSettingsViewController(viewModel: viewModel)
    }

}

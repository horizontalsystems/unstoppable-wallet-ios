import UIKit
import ThemeKit
import MarketKit

class AddressBookAddressModule {

    static func viewController(contact: Contact, currentBlockchainType: BlockchainType?) -> UIViewController? {
        return nil
        guard let contactManager = App.shared.contactManager else {
            return nil
        }

//        let service = AddressBookAddressService(
//                marketKit: App.shared.marketKit,
//                contact: contact)
//        let viewModel = AddressBookAddressViewModel(service: service)
//
//        let controller = AddressBookAddressViewController(viewModel: viewModel, presented: presented)
//        if presented {
//            return ThemeNavigationController(rootViewController: controller)
//        } else {
//            return controller
//        }
    }

}

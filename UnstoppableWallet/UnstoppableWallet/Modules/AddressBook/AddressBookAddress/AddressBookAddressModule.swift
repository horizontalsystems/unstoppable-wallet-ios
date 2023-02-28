import UIKit
import ThemeKit
import MarketKit

class AddressBookAddressModule {

    static func viewController(existAddresses: [ContactAddress], currentAddress: ContactAddress? = nil) -> UIViewController? {
        let service: AddressBookAddressService
        let addressService: AddressService
        if let currentAddress {
            guard let blockchain = try? App.shared.marketKit.blockchain(uid: currentAddress.blockchainUid) else {
                return nil
            }
            addressService = AddressService(mode: .blockchainType(blockchain.type))
            service = AddressBookAddressService(marketKit: App.shared.marketKit, addressService: addressService, mode: .edit(currentAddress), blockchain: blockchain)
        } else {
            let blockchainUids = BlockchainType.supported.map { $0.uid }
            let allBlockchains = ((try? App.shared.marketKit.blockchains(uids: blockchainUids)) ?? []).sorted { $0.type.order < $1.type.order }

            guard let firstBlockchain = allBlockchains.first else {
                return nil
            }
            addressService = AddressService(mode: .blockchainType(firstBlockchain.type))
            service = AddressBookAddressService(marketKit: App.shared.marketKit, addressService: addressService, mode: .create(existAddresses), blockchain: firstBlockchain)
        }

        let viewModel = AddressBookAddressViewModel(service: service)
        let addressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let controller = AddressBookAddressViewController(viewModel: viewModel, addressViewModel: addressViewModel)
        return ThemeNavigationController(rootViewController: controller)
    }

}

extension AddressBookAddressModule {

    enum Mode {
        case create([ContactAddress])
        case edit(ContactAddress)
    }

}

import UIKit
import ThemeKit
import MarketKit

class ContactBookAddressModule {

    static func viewController(contactUid: String?, existAddresses: [ContactAddress], currentAddress: ContactAddress? = nil, onSaveAddress: @escaping (ContactAddress?) -> ()) -> UIViewController? {
        let service: ContactBookAddressService
        let addressService: AddressService
        if let currentAddress {
            guard let blockchain = try? App.shared.marketKit.blockchain(uid: currentAddress.blockchainUid) else {
                return nil
            }
            addressService = AddressService(mode: .blockchainType, marketKit: App.shared.marketKit, contactBookManager: nil, blockchainType: blockchain.type)
            service = ContactBookAddressService(marketKit: App.shared.marketKit, addressService: addressService, contactBookManager: App.shared.contactManager, currentContactUid: contactUid, mode: .edit(currentAddress), blockchain: blockchain)
        } else {
            let blockchainUids = BlockchainType
                    .supported
                    .map { $0.uid }
                    .filter { uid in
                        !existAddresses.contains(where: { address in address.blockchainUid == uid })
                    }

            let allBlockchains = ((try? App.shared.marketKit.blockchains(uids: blockchainUids)) ?? [])
                    .sorted { $0.type.order < $1.type.order }

            guard let firstBlockchain = allBlockchains.first else {
                return nil
            }
            addressService = AddressService(mode: .blockchainType, marketKit: App.shared.marketKit, contactBookManager: nil, blockchainType: firstBlockchain.type)
            service = ContactBookAddressService(marketKit: App.shared.marketKit, addressService: addressService, contactBookManager: App.shared.contactManager, currentContactUid: contactUid, mode: .create(existAddresses), blockchain: firstBlockchain)
        }

        let viewModel = ContactBookAddressViewModel(service: service)
        let addressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let controller = ContactBookAddressViewController(viewModel: viewModel, addressViewModel: addressViewModel, onUpdateAddress: onSaveAddress)
        return ThemeNavigationController(rootViewController: controller)
    }

}

extension ContactBookAddressModule {

    enum Mode {
        case create([ContactAddress])
        case edit(ContactAddress)
    }

}

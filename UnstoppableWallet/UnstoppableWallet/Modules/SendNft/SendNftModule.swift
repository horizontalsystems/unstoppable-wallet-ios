import UIKit
import ThemeKit
import MarketKit

class SendNftModule {

    private static func addressService(nftRecord: NftRecord) -> AddressService {
        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, blockchainType: nftRecord.blockchainType)

        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)

        if let ensAddressParserItem = EnsAddressParserItem(rpcSource: App.shared.evmSyncSourceManager.infuraRpcSource, rawAddressParserItem: evmAddressParserItem) {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: nftRecord.blockchainType)
        return AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)
    }

    private static func eip721ViewController(evmKitWrapper: EvmKitWrapper, nftRecord: EvmNftRecord, adapter: INftAdapter) -> UIViewController {
        let addressService = addressService(nftRecord: nftRecord)
        let service = SendEip721Service(nftRecord: nftRecord, adapter: adapter, addressService: addressService)

        let recipientAddressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let viewModel = SendEip721ViewModel(service: service)

        return SendEip721ViewController(evmKitWrapper: evmKitWrapper, viewModel: viewModel, recipientViewModel: recipientAddressViewModel)
    }

    static func viewController(nftUid: NftUid) -> UIViewController? {
        guard let account = App.shared.accountManager.activeAccount, !account.watchAccount else {
            return nil
        }

        let nftKey = NftKey(account: account, blockchainType: nftUid.blockchainType)

        guard let adapter = App.shared.nftAdapterManager.adapter(nftKey: nftKey) else {
            return nil
        }

        guard let nftRecord = adapter.nftRecord(nftUid: nftUid) else {
            return nil
        }

        let evmBlockchainManager = App.shared.evmBlockchainManager
        guard let evmKitWrapper = try? evmBlockchainManager
                .evmKitManager(blockchainType: nftRecord.blockchainType)
                .evmKitWrapper(account: account, blockchainType: nftRecord.blockchainType) else {
            return nil
        }

        let viewController: UIViewController

        switch nftUid {
        case .evm:
            guard let evmNftRecord = nftRecord as? EvmNftRecord else {
                return nil
            }

            switch evmNftRecord.type {
            case .eip721:
                viewController = eip721ViewController(evmKitWrapper: evmKitWrapper, nftRecord: evmNftRecord, adapter: adapter)
            case .eip1155:
                viewController = UIViewController()
            }

        default:
            return nil
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

}

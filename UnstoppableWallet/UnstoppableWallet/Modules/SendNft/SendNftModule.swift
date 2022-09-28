import UIKit
import ThemeKit
import MarketKit

class SendNftModule {

    private static func addressService(blockchainType: BlockchainType) -> AddressService {
        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, blockchainType: blockchainType)

        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)

        if let ensAddressParserItem = EnsAddressParserItem(rpcSource: App.shared.evmSyncSourceManager.infuraRpcSource, rawAddressParserItem: evmAddressParserItem) {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: blockchainType)
        return AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)
    }

    private static func eip721ViewController(evmKitWrapper: EvmKitWrapper, nftUid: NftUid, adapter: INftAdapter) -> UIViewController {
        let addressService = addressService(blockchainType: nftUid.blockchainType)
        let service = SendEip721Service(nftUid: nftUid, adapter: adapter, addressService: addressService, nftMetadataManager: App.shared.nftMetadataManager)

        let recipientAddressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)
        let viewModel = SendEip721ViewModel(service: service)

        return SendEip721ViewController(evmKitWrapper: evmKitWrapper, viewModel: viewModel, recipientViewModel: recipientAddressViewModel)
    }

    private static func eip1155ViewController(evmKitWrapper: EvmKitWrapper, nftUid: NftUid, balance: Int, adapter: INftAdapter) -> UIViewController {
        let addressService = addressService(blockchainType: nftUid.blockchainType)
        let service = SendEip1155Service(nftUid: nftUid, balance: balance, adapter: adapter, addressService: addressService, nftMetadataManager: App.shared.nftMetadataManager)

        let viewModel = SendEip1155ViewModel(service: service)
        let availableBalanceViewModel = SendEip1155AvailableBalanceViewModel(service: service)

        let amountViewModel = IntegerAmountInputViewModel(service: service)
        let recipientAddressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        return SendEip1155ViewController(evmKitWrapper: evmKitWrapper, viewModel: viewModel, availableBalanceViewModel: availableBalanceViewModel, amountViewModel: amountViewModel, recipientViewModel: recipientAddressViewModel)
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
                .evmKitManager(blockchainType: nftUid.blockchainType)
                .evmKitWrapper(account: account, blockchainType: nftUid.blockchainType) else {
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
                viewController = eip721ViewController(evmKitWrapper: evmKitWrapper, nftUid: nftUid, adapter: adapter)
            case .eip1155:
                viewController = eip1155ViewController(evmKitWrapper: evmKitWrapper, nftUid: nftUid, balance: nftRecord.balance, adapter: adapter)
            }

        default:
            return nil
        }

        return ThemeNavigationController(rootViewController: viewController)
    }

}

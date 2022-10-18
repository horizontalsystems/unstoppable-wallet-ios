import UIKit
import ThemeKit
import MarketKit

struct WatchModule {

    static func viewController(sourceViewController: UIViewController? = nil) -> UIViewController {
        let ethereumToken = try? App.shared.marketKit.token(query: TokenQuery(blockchainType: .ethereum, tokenType: .native))

        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UdnAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, coinCode: "ETH", token: ethereumToken)
        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)

        if let ensAddressParserItem = EnsAddressParserItem(rpcSource: App.shared.evmSyncSourceManager.infuraRpcSource, rawAddressParserItem: evmAddressParserItem) {
            addressParserChain.append(handler: ensAddressParserItem)
        }

        let addressUriParser = AddressParserFactory.parser(blockchainType: .ethereum)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        let evmAddressService = WatchEvmAddressService(addressService: addressService)
        let evmAddressViewModel = WatchEvmAddressViewModel(service: evmAddressService)

        let publicKeyService = WatchPublicKeyService()
        let publicKeyViewModel = WatchPublicKeyViewModel(service: publicKeyService)

        let service = WatchService(
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager
        )
        let viewModel = WatchViewModel(
                service: service,
                evmAddressViewModel: evmAddressViewModel,
                publicKeyViewModel: publicKeyViewModel
        )

        let addressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        let viewController = WatchViewController(
                viewModel: viewModel,
                addressViewModel: addressViewModel,
                publicKeyViewModel: publicKeyViewModel,
                sourceViewController: sourceViewController
        )

        return ThemeNavigationController(rootViewController: viewController)
    }

}

import UIKit
import ThemeKit
import MarketKit

struct WatchAddressModule {

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

        let service = WatchAddressService(
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                addressService: addressService
        )
        let viewModel = WatchAddressViewModel(service: service)

        let addressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        let viewController = WatchAddressViewController(viewModel: viewModel, addressViewModel: addressViewModel, sourceViewController: sourceViewController)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

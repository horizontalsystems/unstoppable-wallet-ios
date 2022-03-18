import UIKit
import ThemeKit

struct WatchAddressModule {

    static func viewController() -> UIViewController {
        let evmAddressParserItem = EvmAddressParser()
        let udnAddressParserItem = UDNAddressParserItem.item(rawAddressParserItem: evmAddressParserItem, coinCode: "ETH", coinType: .ethereum)
        let addressParserChain = AddressParserChain()
                .append(handler: evmAddressParserItem)
                .append(handler: udnAddressParserItem)


        let addressUriParser = AddressParserFactory.parser(coinType: .ethereum)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        let service = WatchAddressService(
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                evmBlockchainManager: App.shared.evmBlockchainManager,
                addressService: addressService
        )
        let viewModel = WatchAddressViewModel(service: service)

        let addressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        let viewController = WatchAddressViewController(viewModel: viewModel, addressViewModel: addressViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

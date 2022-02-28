import UIKit
import ThemeKit

struct WatchAddressModule {

    static func viewController() -> UIViewController {
        let addressParserChain = AddressParserChain()
        addressParserChain.append(handler: EvmAddressParser())
        addressParserChain.append(handler: UDNAddressParserItem(coinCode: "ETH", platformCoinCode: nil, chain: nil))

        let addressUriParser = AddressParserFactory.parser(coinType: .ethereum)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        let service = WatchAddressService(
                accountFactory: App.shared.accountFactory,
                accountManager: App.shared.accountManager,
                coinManager: App.shared.coinManager,
                walletManager: App.shared.walletManager,
                addressService: addressService
        )
        let viewModel = WatchAddressViewModel(service: service)

        let addressViewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: nil)

        let viewController = WatchAddressViewController(viewModel: viewModel, addressViewModel: addressViewModel)

        return ThemeNavigationController(rootViewController: viewController)
    }

}

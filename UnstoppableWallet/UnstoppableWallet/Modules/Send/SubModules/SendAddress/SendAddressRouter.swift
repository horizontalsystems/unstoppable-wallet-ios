import UIKit
import MarketKit

class SendAddressRouter: ISendSubRouter {
    weak var viewController: UIViewController?
}

extension SendAddressRouter: ISendAddressRouter {

    func openScan(controller: UIViewController) {
        viewController?.present(controller, animated: true)
    }

}

extension SendAddressRouter {

    static func module(platformCoin: PlatformCoin, addressParserChain: AddressParserChain, isResolutionEnabled: Bool = true) -> (UIView, ISendAddressModule, ISendSubRouter) {
        let router = SendAddressRouter()
        let presenter = SendAddressPresenter(router: router)

        let addressUriParser = AddressParserFactory.parser(coinType: platformCoin.coinType)
        let addressService = AddressService(addressUriParser: addressUriParser, addressParserChain: addressParserChain)

        let viewModel = RecipientAddressViewModel(service: addressService, handlerDelegate: presenter)
        let view = SendAddressView(viewModel: viewModel, isResolutionEnabled: isResolutionEnabled, delegate: presenter)

        return (view, presenter, router)
    }

}

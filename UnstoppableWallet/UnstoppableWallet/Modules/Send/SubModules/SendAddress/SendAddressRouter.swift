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

    static func module(platformCoin: PlatformCoin, isResolutionEnabled: Bool = true) -> (UIView, ISendAddressModule, ISendSubRouter) {
        let addressParserFactory = AddressParserFactory()

        let router = SendAddressRouter()
        let presenter = SendAddressPresenter(router: router)

        let resolutionService = AddressResolutionService(
                coinCode: platformCoin.coin.code,
                chain: nil,
                isResolutionEnabled: isResolutionEnabled)

        let viewModel = RecipientAddressViewModel(
                service: presenter,
                resolutionService: resolutionService,
                addressParser: addressParserFactory.parser(coinType: platformCoin.coinType)
        )
        let view = SendAddressView(viewModel: viewModel, isResolutionEnabled: isResolutionEnabled, delegate: presenter)

        return (view, presenter, router)
    }

}

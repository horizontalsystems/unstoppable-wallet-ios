import UIKit

class SendAddressRouter: ISendSubRouter {
    weak var viewController: UIViewController?
}

extension SendAddressRouter: ISendAddressRouter {

    func openScan(controller: UIViewController) {
        viewController?.present(controller, animated: true)
    }

}

extension SendAddressRouter {

    static func module(coin: Coin, placeholder: String = "send.address_placeholder".localized, isResolutionEnabled: Bool = true) -> (UIView, ISendAddressModule, ISendSubRouter) {
        let addressParserFactory = AddressParserFactory()

        let router = SendAddressRouter()
        let presenter = SendAddressPresenter(router: router)

        let resolutionService = AddressResolutionService(coinCode: coin.code, isResolutionEnabled: isResolutionEnabled)

        let viewModel = RecipientAddressViewModel(
                service: presenter,
                resolutionService: resolutionService,
                addressParser: addressParserFactory.parser(coin: coin)
        )
        let view = SendAddressView(viewModel: viewModel, placeholder: placeholder, delegate: presenter)

        return (view, presenter, router)
    }

}

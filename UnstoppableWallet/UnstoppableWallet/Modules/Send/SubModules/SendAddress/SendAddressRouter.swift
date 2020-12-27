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

    static func module(coin: Coin) -> (UIView, ISendAddressModule, ISendSubRouter) {
        let addressParserFactory = AddressParserFactory()

        let router = SendAddressRouter()
        let interactor = SendAddressInteractor(addressParser: addressParserFactory.parser(coin: coin))

        let presenter = SendAddressPresenter(interactor: interactor, router: router)
        let viewModel = RecipientAddressViewModel(service: presenter)
        let view = SendAddressView(viewModel: viewModel, delegate: presenter)

        return (view, presenter, router)
    }

}

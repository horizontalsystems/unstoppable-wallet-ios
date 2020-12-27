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

    static func module(coin: Coin, placeholder: String = "send.address_placeholder".localized) -> (UIView, ISendAddressModule, ISendSubRouter) {
        let router = SendAddressRouter()
        let presenter = SendAddressPresenter(router: router)
        let viewModel = RecipientAddressViewModel(service: presenter)
        let view = SendAddressView(viewModel: viewModel, placeholder: placeholder, delegate: presenter)

        return (view, presenter, router)
    }

}

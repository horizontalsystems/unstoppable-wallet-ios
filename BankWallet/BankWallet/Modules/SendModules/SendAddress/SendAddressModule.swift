import UIKit

protocol ISendAddressView: class {
    func set(address: String?, error: String?)
}

protocol ISendAddressViewDelegate {
    func onAddressScanClicked()
    func onAddressPasteClicked()
    func onAddressDeleteClicked()
}

protocol ISendAddressPresenterDelegate: class {
    func onAddressUpdate(address: String?)
    func onAmountUpdate(amount: Decimal)
}

protocol ISendAddressInteractor {
    var valueFromPasteboard: String? { get }
    func parse(paymentAddress: String) -> PaymentRequestAddress
    func validate(address: String) throws
}

protocol ISendAddressInteractorDelegate: class {
}

protocol ISendAddressRouter {
    func scanQrCode(onCodeParse: ((String) -> ())?)
}

protocol ISendAddressModule: ISendModule {
}

class SendAddressModule {
    private let sendView: SendAddressView
    private let presenter: SendAddressPresenter


    init(viewController: UIViewController, adapter: IAdapter, delegate: ISendAddressPresenterDelegate) {
        let router = SendAddressRouter()

        let interactor = SendAddressInteractor(pasteboardManager: App.shared.pasteboardManager, adapter: adapter)

        presenter = SendAddressPresenter(interactor: interactor, router: router)
        sendView = SendAddressView(delegate: presenter)

        presenter.view = sendView
        presenter.presenterDelegate = delegate
        router.viewController = viewController
    }

}

extension SendAddressModule: ISendModule {

    var view: UIView {
        return sendView
    }

    var height: CGFloat {
        return SendTheme.addressHeight
    }

    func viewDidLoad() {
        //
    }

}

extension SendAmountModule: ISendAddressModule {

}

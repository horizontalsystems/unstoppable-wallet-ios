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
    func parse(paymentAddress: String) -> PaymentRequestAddress

    func onAddressUpdate(address: String?)
    func onAmountUpdate(amount: Decimal)
}

protocol ISendAddressInteractor {
    var valueFromPasteboard: String? { get }
}

protocol ISendAddressInteractorDelegate: class {
}

protocol ISendAddressRouter {
    func scanQrCode(onCodeParse: ((String) -> ())?)
}

protocol ISendAddressModule {
    var address: String? { get }
    var validState: Bool { get }
}

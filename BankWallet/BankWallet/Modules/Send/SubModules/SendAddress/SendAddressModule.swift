import UIKit

protocol ISendAddressView: class {
    func set(address: String?, error: String?)
}

protocol ISendAddressViewDelegate {
    func onAddressScanClicked()
    func onAddressPasteClicked()
    func onAddressDeleteClicked()
}

protocol ISendAddressDelegate: class {
    func parse(paymentAddress: String) -> PaymentRequestAddress

    func onAddressUpdate(address: String?)
    func onAmountUpdate(amount: Decimal)

    func scanQrCode(delegate: IScanQrCodeDelegate)
}

protocol ISendAddressInteractor {
    var valueFromPasteboard: String? { get }
}

protocol ISendAddressInteractorDelegate: class {
}

protocol ISendAddressModule: AnyObject {
    var delegate: ISendAddressDelegate? { get set }

    var address: String? { get }
    var validState: Bool { get }
}

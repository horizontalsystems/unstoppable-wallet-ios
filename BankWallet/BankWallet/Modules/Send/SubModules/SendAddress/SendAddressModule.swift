import Foundation

protocol ISendAddressView: class {
    func set(address: String?, error: String?)
}

protocol ISendAddressViewDelegate {
    func onAddressScanClicked()
    func onAddressPasteClicked()
    func onAddressDeleteClicked()
}

protocol ISendAddressInteractor {
    var valueFromPasteboard: String? { get }
    func parse(address: String) -> (String, Decimal?)
}

protocol ISendAddressModule: AnyObject {
    var delegate: ISendAddressDelegate? { get set }

    var address: String? { get }
}

protocol ISendAddressDelegate: class {
    func validate(address: String) throws

    func onUpdateAddress()
    func onUpdate(amount: Decimal)

    func scanQrCode(delegate: IScanQrCodeDelegate)
}

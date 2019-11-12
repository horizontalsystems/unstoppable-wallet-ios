import Foundation

protocol ISendAddressView: class {
    func set(address: String?, error: Error?)
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

    var currentAddress: String? { get }
    func validateAddress() throws
    func validAddress() throws -> String
}

protocol ISendAddressDelegate: class {
    func validate(address: String) throws

    func onUpdateAddress()
    func onUpdate(amount: Decimal)
}

protocol ISendAddressRouter {
    func scanQrCode(delegate: IScanQrCodeDelegate)
}

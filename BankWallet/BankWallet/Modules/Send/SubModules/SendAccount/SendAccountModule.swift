protocol ISendAccountView: class {
    func set(account: String?, error: String?)
}

protocol ISendAccountViewDelegate {
    func onScanClicked()
    func onPasteClicked()
    func onChange(account: String?)
    func onDeleteClicked()
}

protocol ISendAccountInteractor {
    var valueFromPasteboard: String? { get }
}

protocol ISendAccountModule: AnyObject {
    var delegate: ISendAccountDelegate? { get set }

    var account: String? { get }
}

protocol ISendAccountDelegate: class {
    func validate(account: String) throws

    func onUpdateAccount()

    func scanQrCode(delegate: IScanQrCodeDelegate)
}

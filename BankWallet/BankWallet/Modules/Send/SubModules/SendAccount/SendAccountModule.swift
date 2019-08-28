protocol ISendAccountView: class {
    func set(account: String?, error: Error?)
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

    var currentAccount: String? { get }
    func validAccount() throws -> String
}

protocol ISendAccountDelegate: class {
    func validate(account: String) throws

    func onUpdateAccount()
}

protocol ISendAccountRouter {
    func scanQrCode(delegate: IScanQrCodeDelegate)
}

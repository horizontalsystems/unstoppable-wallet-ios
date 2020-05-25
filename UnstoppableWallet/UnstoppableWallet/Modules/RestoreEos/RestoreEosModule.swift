protocol IRestoreEosView: class {
    func showNextButton()
    func showRestoreButton()
    func set(account: String?)
    func set(key: String?)
    func show(error: Error)
}

protocol IRestoreEosViewDelegate {
    func viewDidLoad()
    func onPasteAccountClicked()
    func onChange(account: String?)
    func onDeleteAccount()
    func onPasteKeyClicked()
    func onDeleteKey()

    func didTapCancel()
    func didTapDone()
    func didTapScanQr()
}

protocol IRestoreEosInteractor {
    var defaultCredentials: (String, String) { get }
    var valueFromPasteboard: String? { get }
    func validate(privateKey: String) throws
    func validate(account: String) throws
}

protocol IRestoreEosInteractorDelegate: class {
}

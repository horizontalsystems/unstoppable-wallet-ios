protocol IRestoreEosView: class {
    func showCancelButton()
    func set(account: String?)
    func set(key: String?)
}

protocol IRestoreEosViewDelegate {
    func viewDidLoad()
    func onPasteAccountClicked()
    func onChange(account: String?)
    func onDeleteAccount()
    func onPasteKeyClicked()
    func onScan(key: String)
    func onDeleteKey()

    func didTapCancel()
    func didTapDone()
}

protocol IRestoreEosRouter {
    func dismiss()
}

protocol IRestoreEosInteractor {
    var valueFromPasteboard: String? { get }
}

protocol IRestoreEosInteractorDelegate: class {
}

protocol IBackupEosView: class {
}

protocol IBackupEosViewDelegate {
    var account: String { get }
    var activePrivateKey: String { get }
    func didTapClose()
}

protocol IBackupEosPresenter {
}

protocol IBackupEosRouter {
    func notifyClosed()
}

class BackupEosPresenter: IBackupEosPresenter {
    private let router: IBackupEosRouter
    private let interactor: IBackupEosInteractor
    weak var view: IBackupEosView?

    let account: String
    let activePrivateKey: String

    init(interactor: IBackupEosInteractor, router: IBackupEosRouter, account: String, activePrivateKey: String) {
        self.interactor = interactor
        self.router = router
        self.account = account
        self.activePrivateKey = activePrivateKey
    }

}

extension BackupEosPresenter: IBackupEosViewDelegate {

    func didTapClose() {
        router.notifyClosed()
    }

    func onCopyAddress() {
        interactor.copyToClipboard(string: account)
        view?.showCopied()
    }

    func onCopyPrivateKey() {
        interactor.copyToClipboard(string: activePrivateKey)
        view?.showCopied()
    }

}

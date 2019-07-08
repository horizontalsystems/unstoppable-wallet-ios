class BackupPresenter: IBackupPresenter {
    weak var view: IBackupWordsView? = nil

    private let router: IBackupRouter
    private let interactor: IBackupInteractor
    private let account: Account

    init(interactor: IBackupInteractor, router: IBackupRouter, account: Account) {
        self.interactor = interactor
        self.router = router
        self.account = account
    }

}

extension BackupPresenter: IBackupViewDelegate {

    func cancelDidClick() {
        router.close()
    }

    func backupDidTap() {
        router.showUnlock()
    }

}

extension BackupPresenter: IUnlockDelegate {

    func onUnlock() {
        switch account.type {
        case .mnemonic(let words, _, _): router.show(words: words, delegate: self)
        case .eos: router.showEOS(account: account, delegate: self)
        default: ()
        }
    }

    func onCancelUnlock() {

    }

}

extension BackupPresenter: IBackupDelegate {

    func didBackUp() {
        interactor.setBackedUp(accountId: account.id)
        router.close()
    }

}

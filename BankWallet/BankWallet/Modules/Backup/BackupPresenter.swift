class BackupPresenter: IBackupPresenter {
    weak var view: IBackupWordsView? = nil

    private let router: IBackupRouter
    private let accountManager: IAccountManager
    private let account: Account

    init(router: IBackupRouter, accountManager: IAccountManager, account: Account) {
        self.accountManager = accountManager
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
        accountManager.setAccountBackedUp(id: account.id)
        router.close()
    }

}

import PinKit

class BackupPresenter: IBackupPresenter {
    weak var view: IBackupWordsView?

    private let router: IBackupRouter
    private let interactor: IBackupInteractor
    private let account: Account
    private let predefinedAccountType: PredefinedAccountType

    init(interactor: IBackupInteractor, router: IBackupRouter, account: Account, predefinedAccountType: PredefinedAccountType) {
        self.interactor = interactor
        self.router = router
        self.account = account
        self.predefinedAccountType = predefinedAccountType
    }

}

extension BackupPresenter: IBackupViewDelegate {

    var isBackedUp: Bool {
        account.backedUp
    }

    var coinCodes: String {
        predefinedAccountType.coinCodes
    }

    func cancelDidClick() {
        router.close()
    }

    func proceedDidTap() {
        if interactor.isPinSet {
            router.showUnlock(delegate: self)
        } else {
            router.showBackup(account: account, predefinedAccountType: predefinedAccountType, delegate: self)
        }
    }

}

extension BackupPresenter: IUnlockDelegate {

    func onUnlock() {
        router.showBackup(account: account, predefinedAccountType: predefinedAccountType, delegate: self)
    }

    func onCancelUnlock() {
    }

}

extension BackupPresenter: IBackupDelegate {

    func didBackUp() {
        interactor.setBackedUp(accountId: account.id)
        router.close()
    }

    func didClose() {
        router.close()
    }

}

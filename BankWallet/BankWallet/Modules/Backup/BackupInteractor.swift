class BackupInteractor {
    weak var delegate: IBackupInteractorDelegate?

    private let accountId: String
    private let accountManager: IAccountManager
    private let randomManager: IRandomManager

    init(accountId: String, accountManager: IAccountManager, randomManager: IRandomManager) {
        self.accountId = accountId
        self.accountManager = accountManager
        self.randomManager = randomManager
    }

}

extension BackupInteractor: IBackupInteractor {

    func setBackedUp() {
        accountManager.setAccountBackedUp(id: accountId)
    }

    func fetchConfirmationIndexes(max: Int, count: Int) -> [Int] {
        return randomManager.getRandomIndexes(max: max, count: count)
    }

}

extension BackupInteractor: IUnlockDelegate {

    func onUnlock() {
        delegate?.didUnlock()
    }

    func onCancelUnlock() {
    }

}

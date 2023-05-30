import RxSwift
import RxRelay
import Combine
import HsExtensions

class BackupManager {
    private let accountManager: AccountManager
    private let cloudBackupManager: CloudAccountBackupManager

    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let allBackedUpRelay = PublishRelay<Bool>()

    @PostPublished var items: [String: WalletBackup]

    init(accountManager: AccountManager, cloudBackupManager: CloudAccountBackupManager) {
        self.accountManager = accountManager
        self.cloudBackupManager = cloudBackupManager

        items = cloudBackupManager.items

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] _ in self?.updateAllBackedUp() }
        cloudBackupManager.$items
                .sink { [weak self] _ in
                    self?.updateAllBackedUp()
                }
                .store(in: &cancellables)

    }

    private func updateAllBackedUp() {
        allBackedUpRelay.accept(allBackedUp)
    }

}

extension BackupManager {

    var allBackedUp: Bool {
        accountManager.accounts.allSatisfy { $0.backedUp || cloudBackupManager.backedUp(uniqueId: $0.type.uniqueId()) }
    }

    var allBackedUpObservable: Observable<Bool> {
        allBackedUpRelay.asObservable()
    }

    func setAccountBackedUp(id: String) {
        guard let account = accountManager.account(id: id) else {
            return
        }

        account.backedUp = true
        accountManager.update(account: account)
    }

}

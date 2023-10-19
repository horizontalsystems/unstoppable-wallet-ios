import RxSwift
import RxRelay
import Combine

class ManageAccountsService {
    private let accountManager: AccountManager
    private let cloudBackupManager: CloudBackupManager
    private let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountManager: AccountManager, cloudBackupManager: CloudBackupManager) {
        self.accountManager = accountManager
        self.cloudBackupManager = cloudBackupManager

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] _ in self?.syncItems() }
        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.syncItems() }

        cloudBackupManager.$oneWalletItems
                .sink { [weak self] _ in
                    self?.syncItems()
                }
                .store(in: &cancellables)

        syncItems()
    }

    private func syncItems() {
        let activeAccount = accountManager.activeAccount
        items = accountManager.accounts.map { account in
            let cloudBackedUp = cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
            return Item(account: account, cloudBackedUp: cloudBackedUp, isActive: account == activeAccount)
        }
    }

}

extension ManageAccountsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var lastCreatedAccount: Account? {
        accountManager.popLastCreatedAccount()
    }

    var hasAccounts: Bool {
        !accountManager.accounts.isEmpty
    }

    func set(activeAccountId: String) {
        accountManager.set(activeAccountId: activeAccountId)
    }

}

extension ManageAccountsService {

    struct Item {
        let account: Account
        let cloudBackedUp: Bool
        let isActive: Bool

        var hasAlertDescription: Bool {
            !(account.backedUp || cloudBackedUp)
        }

        var hasAlert: Bool {
            !account.backedUp
        }
    }

}

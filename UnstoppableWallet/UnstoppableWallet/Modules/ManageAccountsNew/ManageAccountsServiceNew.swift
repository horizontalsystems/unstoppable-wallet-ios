import RxSwift
import RxRelay

class ManageAccountsServiceNew {
    private let accountManager: IAccountManager
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountManager: IAccountManager) {
        self.accountManager = accountManager

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] _ in self?.syncItems() }
        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.syncItems() }

        syncItems()
    }

    private func syncItems() {
        let activeAccount = accountManager.activeAccount
        items = accountManager.accounts.map { account in
            Item(account: account, isActive: account == activeAccount)
        }
    }

}

extension ManageAccountsServiceNew {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    func set(activeAccountId: String) {
        accountManager.set(activeAccountId: activeAccountId)
    }

}

extension ManageAccountsServiceNew {

    struct Item {
        let account: Account
        let isActive: Bool
    }

}

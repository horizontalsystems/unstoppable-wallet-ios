import RxSwift
import RxRelay
import Contacts
import EvmKit

class ManageAccountsService {
    private let accountManager: AccountManager
    private var contactManager: ContactManager?
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(accountManager: AccountManager) {
        self.accountManager = accountManager

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] _ in self?.syncItems() }
        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.syncItems() }

        let contactManager = ContactManager(localStorage: App.shared.localStorage)
        self.contactManager = contactManager

        App.shared.localStorage.remoteSync = true
        syncItems()
    }

    private func syncItems() {
        let activeAccount = accountManager.activeAccount
        items = accountManager.accounts.map { account in
            Item(account: account, isActive: account == activeAccount)
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

    func onTapEdit(accountId: String) {
        guard let contactManager else {
            return
        }
        print("===> Contacts:")
        print(contactManager.contacts ?? [])

        let newContact = Contact(name: "Ant013", addresses: [
            ContactAddress(blockhainUid: "btc", address: "bc1sdjfshsdk")
        ])

        do {
            try contactManager.update(contact: newContact)
        } catch {
            print(error)
        }
    }

}

extension ManageAccountsService {

    struct Item {
        let account: Account
        let isActive: Bool
    }

}

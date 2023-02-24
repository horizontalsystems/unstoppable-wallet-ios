import RxSwift
import RxRelay
import Contacts
import EvmKit

class ManageAccountsService {
    private let accountManager: AccountManager
    private var contactService: ContactManager?
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

        App.shared.localStorage.remoteSync = true

        contactService = ContactManager(localStorage: App.shared.localStorage)
        contactService?.sync()

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
        guard let contactService else {
            return
        }
        print("===> Contacts:")
        print(contactService.contacts ?? [])

        let newContact = Contact(uid: UUID().uuidString, name: "Ant013", addresses: [
            ContactAddress(blockchainUid: "btc", address: "bc1sdjfshsdk")
        ])

        do {
            try contactService.update(contact: newContact)
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

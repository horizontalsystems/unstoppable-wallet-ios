import RxSwift
import RxRelay
import RxCocoa

class ManageAccountsViewModelNew {
    private let service: ManageAccountsServiceNew
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: ManageAccountsServiceNew) {
        self.service = service

        subscribe(disposeBag, service.accountsObservable) { [weak self] in self?.sync(accounts: $0) }

        sync(accounts: service.accounts)
    }

    private func sync(accounts: [Account]) {
        let sortedAccounts = accounts.sorted { $0.name < $1.name }
        let viewItems = sortedAccounts.map { viewItem(account: $0) }
        viewItemsRelay.accept(viewItems)
    }

    private func viewItem(account: Account) -> ViewItem {
        ViewItem(
                accountId: account.id,
                title: account.name,
                subtitle: description(accountType: account.type),
                selected: false,
                alert: !account.backedUp
        )
    }

    private func description(accountType: AccountType) -> String {
        switch accountType {
        case .mnemonic(let words, let salt):
            let count = words.count
            return salt == nil ? "\(count) words" : "\(count) words with passphrase"
        default:
            return ""
        }
    }

}

extension ManageAccountsViewModelNew {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func onSelect(accountId: String) {
        print("Select \(accountId)")
    }

}

extension ManageAccountsViewModelNew {

    struct ViewItem {
        let accountId: String
        let title: String
        let subtitle: String
        let selected: Bool
        let alert: Bool
    }

}

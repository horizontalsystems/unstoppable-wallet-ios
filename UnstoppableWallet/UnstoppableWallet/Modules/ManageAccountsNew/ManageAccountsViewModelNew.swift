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
        viewItemsRelay.accept(accounts.map { viewItem(account: $0) })
    }

    private func viewItem(account: Account) -> ViewItem {
        ViewItem(
                id: account.id,
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

    func onSelect(index: Int) {
        print("Select \(index)")
    }

    func onEdit(index: Int) {
        print("Edit \(index)")
    }

}

extension ManageAccountsViewModelNew {

    struct ViewItem {
        let id: String
        let title: String
        let subtitle: String
        let selected: Bool
        let alert: Bool
    }

}

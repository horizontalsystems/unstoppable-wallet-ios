import RxSwift
import RxRelay
import RxCocoa

class ManageAccountsViewModelNew {
    private let service: ManageAccountsServiceNew
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: ManageAccountsServiceNew) {
        self.service = service

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [ManageAccountsServiceNew.Item]) {
        let sortedItems = items.sorted { $0.account.name < $1.account.name }
        let viewItems = items.map { viewItem(item: $0) }
        viewItemsRelay.accept(viewItems)
    }

    private func viewItem(item: ManageAccountsServiceNew.Item) -> ViewItem {
        ViewItem(
                accountId: item.account.id,
                title: item.account.name,
                subtitle: description(accountType: item.account.type),
                selected: item.isActive,
                alert: !item.account.backedUp
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
        service.set(activeAccountId: accountId)
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

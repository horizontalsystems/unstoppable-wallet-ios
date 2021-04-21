import RxSwift
import RxRelay
import RxCocoa

class ManageAccountsViewModel {
    private let service: ManageAccountsService
    private let mode: ManageAccountsModule.Mode
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let finishRelay = PublishRelay<()>()

    init(service: ManageAccountsService, mode: ManageAccountsModule.Mode) {
        self.service = service
        self.mode = mode

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [ManageAccountsService.Item]) {
        let sortedItems = items.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }
        let viewItems = sortedItems.map { viewItem(item: $0) }
        viewItemsRelay.accept(viewItems)
    }

    private func viewItem(item: ManageAccountsService.Item) -> ViewItem {
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
            let count = "\(words.count)"
            return salt.isEmpty ? "manage_accounts.n_words".localized(count) : "manage_accounts.n_words_with_passphrase".localized(count)
        default:
            return ""
        }
    }

}

extension ManageAccountsViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var isDoneVisible: Bool {
        mode == .switcher
    }

    func onSelect(accountId: String) {
        service.set(activeAccountId: accountId)

        if mode == .switcher {
            finishRelay.accept(())
        }
    }

}

extension ManageAccountsViewModel {

    struct ViewItem {
        let accountId: String
        let title: String
        let subtitle: String
        let selected: Bool
        let alert: Bool
    }

}

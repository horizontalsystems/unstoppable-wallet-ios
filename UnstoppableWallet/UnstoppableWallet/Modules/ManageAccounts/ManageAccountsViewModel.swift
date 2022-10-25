import RxSwift
import RxRelay
import RxCocoa

class ManageAccountsViewModel {
    private let service: ManageAccountsService
    private let mode: ManageAccountsModule.Mode
    private let disposeBag = DisposeBag()

    private let viewStateRelay = BehaviorRelay<ViewState>(value: ViewState.empty)
    private let finishRelay = PublishRelay<()>()

    init(service: ManageAccountsService, mode: ManageAccountsModule.Mode) {
        self.service = service
        self.mode = mode

        subscribe(disposeBag, service.itemsObservable) { [weak self] in self?.sync(items: $0) }

        sync(items: service.items)
    }

    private func sync(items: [ManageAccountsService.Item]) {
        let sortedItems = items.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }

        let viewState = ViewState(
                regularViewItems: sortedItems.filter { !$0.account.watchAccount }.map { viewItem(item: $0) },
                watchViewItems: sortedItems.filter { $0.account.watchAccount }.map { viewItem(item: $0) }
        )

        viewStateRelay.accept(viewState)
    }

    private func viewItem(item: ManageAccountsService.Item) -> ViewItem {
        ViewItem(
                accountId: item.account.id,
                title: item.account.name,
                subtitle: item.account.type.detailedDescription,
                selected: item.isActive,
                alert: !item.account.backedUp,
                watchAccount: item.account.watchAccount
        )
    }

}

extension ManageAccountsViewModel {

    var viewStateDriver: Driver<ViewState> {
        viewStateRelay.asDriver()
    }

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    var isDoneVisible: Bool {
        mode == .switcher
    }

    var lastCreatedAccount: Account? {
        service.lastCreatedAccount
    }

    var shouldClose: Bool {
        mode == .switcher && !service.hasAccounts
    }

    func onSelect(accountId: String) {
        service.set(activeAccountId: accountId)

        if mode == .switcher {
            finishRelay.accept(())
        }
    }

}

extension ManageAccountsViewModel {

    struct ViewState {
        let regularViewItems: [ViewItem]
        let watchViewItems: [ViewItem]

        static var empty: ViewState {
            ViewState(regularViewItems: [], watchViewItems: [])
        }
    }

    struct ViewItem {
        let accountId: String
        let title: String
        let subtitle: String
        let selected: Bool
        let alert: Bool
        let watchAccount: Bool
    }

}

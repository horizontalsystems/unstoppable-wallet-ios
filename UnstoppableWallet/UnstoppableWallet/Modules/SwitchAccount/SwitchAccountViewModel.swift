import RxSwift
import RxRelay
import RxCocoa

class SwitchAccountViewModel {
    private let service: SwitchAccountService

    private(set) var viewItems = [ViewItem]()
    private let finishRelay = PublishRelay<()>()

    init(service: SwitchAccountService) {
        self.service = service

        let sortedItems = service.items.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }

        let regularViewItems = sortedItems.filter { !$0.account.watchAccount }.map { viewItem(item: $0) }
        let watchViewItems = sortedItems.filter { $0.account.watchAccount }.map { viewItem(item: $0) }

        viewItems = regularViewItems + watchViewItems
    }

    private func viewItem(item: SwitchAccountService.Item) -> ViewItem {
        ViewItem(
                accountId: item.account.id,
                title: item.account.name,
                subtitle: item.account.type.description,
                selected: item.isActive,
                watchAccount: item.account.watchAccount
        )
    }

}

extension SwitchAccountViewModel {

    var finishSignal: Signal<()> {
        finishRelay.asSignal()
    }

    func onSelect(accountId: String) {
        service.set(activeAccountId: accountId)
        finishRelay.accept(())
    }

}

extension SwitchAccountViewModel {

    struct ViewItem {
        let accountId: String
        let title: String
        let subtitle: String
        let selected: Bool
        let watchAccount: Bool
    }

}

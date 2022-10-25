import RxSwift
import RxRelay
import RxCocoa

class SwitchAccountViewModel {
    private let service: SwitchAccountService

    private(set) var regularViewItems = [ViewItem]()
    private(set) var watchViewItems = [ViewItem]()
    private let finishRelay = PublishRelay<()>()

    init(service: SwitchAccountService) {
        self.service = service

        let sortedItems = service.items.sorted { $0.account.name.lowercased() < $1.account.name.lowercased() }

        regularViewItems = sortedItems.filter { !$0.account.watchAccount }.map { viewItem(item: $0) }
        watchViewItems = sortedItems.filter { $0.account.watchAccount }.map { viewItem(item: $0) }
    }

    private func viewItem(item: SwitchAccountService.Item) -> ViewItem {
        ViewItem(
                accountId: item.account.id,
                title: item.account.name,
                subtitle: item.account.type.detailedDescription,
                selected: item.isActive
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
    }

}

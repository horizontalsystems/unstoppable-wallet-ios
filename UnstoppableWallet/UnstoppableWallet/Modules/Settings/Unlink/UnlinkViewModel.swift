import RxCocoa
import RxRelay
import RxSwift

class UnlinkViewModel {
    private let service: UnlinkService

    private let viewItemsRelay: BehaviorRelay<[ViewItem]>
    private let deleteEnabledRelay = BehaviorRelay<Bool>(value: false)
    private let successRelay = PublishRelay<Void>()

    init(service: UnlinkService) {
        self.service = service

        viewItemsRelay = BehaviorRelay(value: [
            ViewItem(text: "settings_manage_keys.delete.confirmation_remove".localized),
            ViewItem(text: "settings_manage_keys.delete.confirmation_loose".localized),
        ])

        syncDeleteEnabled()
    }

    private func syncDeleteEnabled() {
        deleteEnabledRelay.accept(viewItemsRelay.value.allSatisfy(\.checked))
    }
}

extension UnlinkViewModel {
    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var deleteEnabledDriver: Driver<Bool> {
        deleteEnabledRelay.asDriver()
    }

    var successSignal: Signal<Void> {
        successRelay.asSignal()
    }

    var accountName: String {
        service.account.name
    }

    func onTap(index: Int) {
        var viewItems = viewItemsRelay.value
        viewItems[index].checked = !viewItems[index].checked
        viewItemsRelay.accept(viewItems)

        syncDeleteEnabled()
    }

    func onTapDelete() {
        service.deleteAccount()
        successRelay.accept(())
        stat(page: .unlinkWallet, event: .delete(entity: .wallet))
    }
}

extension UnlinkViewModel {
    struct ViewItem {
        let text: String
        var checked: Bool

        init(text: String) {
            self.text = text
            checked = false
        }
    }
}

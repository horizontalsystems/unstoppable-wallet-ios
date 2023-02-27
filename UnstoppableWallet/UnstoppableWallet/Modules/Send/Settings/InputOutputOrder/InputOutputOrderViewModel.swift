import RxSwift
import RxRelay
import RxCocoa
import Foundation

class InputOutputOrderViewModel {
    private let disposeBag = DisposeBag()

    private let service: InputOutputOrderService
    private let selectedItemRelay = BehaviorRelay<String?>(value: nil)
    private let alteredStateRelay = PublishRelay<Void>()

    init(service: InputOutputOrderService) {
        self.service = service

        subscribe(disposeBag, service.selectedItemObservable) { [weak self] in self?.sync(selectedItem: $0) }
        sync(selectedItem: service.selectedItem)
    }

    private func sync(selectedItem: TransactionDataSortMode) {
        selectedItemRelay.accept(selectedItem.title)
    }

}

extension InputOutputOrderViewModel {

    var altered: Bool {
        service.selectedItem != service.initialItem
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    var itemsList: [SelectorModule.ViewItem] {
        service.itemsList.map { item in
            SelectorModule.ViewItem(
                image: nil,
                title: item.title,
                titleColor: .themeLeah,
                subtitle: item.description,
                badge: nil,
                selected: service.selectedItem == item
            )
        }
    }

    func onSelect(_ index: Int) {
        service.set(index: index)
        alteredStateRelay.accept(())
    }

    func reset() {
        service.setSelectedItemFromSettings()
        alteredStateRelay.accept(())
    }

}

extension InputOutputOrderViewModel: IDropDownListViewModel {

    var selectedItemDriver: Driver<String?> {
        selectedItemRelay.asDriver()
    }

}

import RxSwift
import RxRelay
import RxCocoa

class DropDownListViewModel {
    private let disposeBag = DisposeBag()

    private let service: DropDownListService
    private let selectedItemRelay = BehaviorRelay<String?>(value: nil)

    init(service: DropDownListService) {
        self.service = service

        subscribe(disposeBag, service.selectedItemObservable) { [weak self] in self?.sync(selectedItem: $0) }
    }

    private func sync(selectedItem: String) {
        selectedItemRelay.accept(selectedItem)
    }

}

extension DropDownListViewModel {

    var selectedItemDriver: Driver<String?> {
        selectedItemRelay.asDriver()
    }

    var itemsList: [AlertViewItem] {
        service.itemsList.map { item in
            AlertViewItem(text: item, selected: service.selectedItem == item)
        }
    }

    func onSelect(_ index: Int) {
        guard index < service.itemsList.count else {
            return
        }

        service.selectedItem = service.itemsList[index]
    }

}

import RxSwift
import RxRelay
import RxCocoa

class DropDownListService {
    var itemsList: [String]

    private let selectedItemRelay = BehaviorRelay<String>(value: "")
    var selectedItem: String {
        didSet {
            update(selectedItem: selectedItem, old: oldValue)
        }
    }

    init(itemsList: [String], initialValue: String) {
        self.itemsList = itemsList
        selectedItem = initialValue
    }

    private func update(selectedItem: String, old: String) {
        guard old != selectedItem else {
            return
        }

        selectedItemRelay.accept(self.selectedItem)
    }

}

extension DropDownListService {

    var selectedItemObservable: Observable<String> {
        selectedItemRelay.asObservable()
    }

    func set(index: Int) {
        guard itemsList.indices.contains(index) else {
            return
        }

        selectedItem = itemsList[index]
    }

}

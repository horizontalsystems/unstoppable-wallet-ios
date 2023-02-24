import RxSwift
import RxCocoa

class InputOutputOrderService {
    var itemsList: [TransactionDataSortMode]

    private let selectedItemRelay = BehaviorSubject<TransactionDataSortMode>(value: .bip69)
    private(set) var selectedItem: TransactionDataSortMode = .bip69 {
        didSet {
            selectedItemRelay.onNext(selectedItem)
        }
    }

    init(itemsList: [TransactionDataSortMode]) {
        self.itemsList = itemsList
    }

}

extension InputOutputOrderService {

    var selectedItemObservable: Observable<TransactionDataSortMode> {
        selectedItemRelay.asObservable()
    }

    func set(index: Int) {
        guard itemsList.indices.contains(index) else {
            return
        }

        selectedItem = itemsList[index]
    }

}

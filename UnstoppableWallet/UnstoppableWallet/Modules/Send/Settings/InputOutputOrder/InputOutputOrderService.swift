import RxSwift
import RxCocoa
import MarketKit

class InputOutputOrderService {
    private let blockchainType: BlockchainType
    private let blockchainManager: BtcBlockchainManager

    var itemsList: [TransactionDataSortMode]
    private(set) var initialItem: TransactionDataSortMode

    private let selectedItemRelay = BehaviorSubject<TransactionDataSortMode>(value: .bip69)
    private(set) var selectedItem: TransactionDataSortMode = .bip69 {
        didSet {
            if (oldValue != selectedItem) {
                selectedItemRelay.onNext(selectedItem)
            }
        }
    }

    init(blockchainType: BlockchainType, blockchainManager: BtcBlockchainManager, itemsList: [TransactionDataSortMode]) {
        self.blockchainType = blockchainType
        self.blockchainManager = blockchainManager
        self.itemsList = itemsList
        initialItem = blockchainManager.transactionSortMode(blockchainType: blockchainType)

        setSelectedItemFromSettings()
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
        blockchainManager.save(transactionSortMode: selectedItem, blockchainType: blockchainType)
    }

    func setSelectedItemFromSettings() {
        selectedItem = initialItem
    }

}

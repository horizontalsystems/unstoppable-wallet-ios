import RxSwift
import RxCocoa
import MarketKit

class InputOutputOrderService {
    private let blockchainType: BlockchainType
    private let blockchainManager: BtcBlockchainManager

    var itemsList: [TransactionDataSortMode]

    private let selectedItemRelay = BehaviorSubject<TransactionDataSortMode>(value: .bip69)
    private(set) var selectedItem: TransactionDataSortMode = .bip69 {
        didSet {
            selectedItemRelay.onNext(selectedItem)
        }
    }

    init(blockchainType: BlockchainType, blockchainManager: BtcBlockchainManager, itemsList: [TransactionDataSortMode]) {
        self.blockchainType = blockchainType
        self.blockchainManager = blockchainManager
        self.itemsList = itemsList

        setSelectedItemFromSettings()
    }

    private func setSelectedItemFromSettings() {
        selectedItem = blockchainManager.transactionSortMode(blockchainType: blockchainType)
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

}

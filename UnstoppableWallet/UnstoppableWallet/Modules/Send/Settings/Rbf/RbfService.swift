import MarketKit
import RxCocoa
import RxSwift

class RbfService {
    private let blockchainType: BlockchainType
    private let blockchainManager: BtcBlockchainManager

    private(set) var initialValue: Bool
    private(set) var selectedValue: Bool

    init(blockchainType: BlockchainType, blockchainManager: BtcBlockchainManager) {
        self.blockchainType = blockchainType
        self.blockchainManager = blockchainManager
        initialValue = blockchainManager.transactionRbfEnabled(blockchainType: blockchainType)
        selectedValue = initialValue
    }
}

extension RbfService {
    func toggle() {
        selectedValue.toggle()
        blockchainManager.save(rbfEnabled: selectedValue, blockchainType: blockchainType)
    }

    func reset() {
        selectedValue = initialValue
    }
}

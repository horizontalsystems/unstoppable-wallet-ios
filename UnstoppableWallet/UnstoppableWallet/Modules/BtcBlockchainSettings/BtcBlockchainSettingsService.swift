import BitcoinCore
import MarketKit

class BtcBlockchainSettingsService {
    let blockchain: Blockchain
    private let btcBlockchainManager: BtcBlockchainManager

    let restoreModes: [BtcSyncModeItem]
    let currentRestoreMode: BtcRestoreMode

    init(blockchain: Blockchain, btcBlockchainManager: BtcBlockchainManager) {
        self.blockchain = blockchain
        self.btcBlockchainManager = btcBlockchainManager

        restoreModes = BtcRestoreMode.allCases
            .filter { blockchain.type.supports(restoreMode: $0) }
            .map { BtcSyncModeItem(blockchain: blockchain, restoreMode: $0) }
        currentRestoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
    }
}

extension BtcBlockchainSettingsService {
    func save(restoreMode: BtcRestoreMode) {
        btcBlockchainManager.save(restoreMode: restoreMode, blockchainType: blockchain.type)
    }
}

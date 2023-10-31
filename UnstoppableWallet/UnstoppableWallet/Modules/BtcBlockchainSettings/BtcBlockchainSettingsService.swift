import MarketKit
import BitcoinCore

class BtcBlockchainSettingsService {
    let blockchain: Blockchain
    private let btcBlockchainManager: BtcBlockchainManager

    let restoreModes: [BtcSyncModeItem]
    let currentRestoreMode: BtcRestoreMode

    init(blockchain: Blockchain, btcBlockchainManager: BtcBlockchainManager) {
        self.blockchain = blockchain
        self.btcBlockchainManager = btcBlockchainManager

        restoreModes = BtcRestoreMode.allCases.map { restoreMode in
            let syncMode = btcBlockchainManager.apiSyncMode(blockchainType: blockchain.type)
            return BtcSyncModeItem(blockchain: blockchain, restoreMode: restoreMode, syncMode: syncMode)
        }
        currentRestoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
    }

}

extension BtcBlockchainSettingsService {

    func save(restoreMode: BtcRestoreMode) {
        btcBlockchainManager.save(restoreMode: restoreMode, blockchainType: blockchain.type)
    }

}

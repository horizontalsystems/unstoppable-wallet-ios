import MarketKit

class BtcBlockchainSettingsService {
    let blockchain: Blockchain
    private let btcBlockchainManager: BtcBlockchainManager

    let currentRestoreMode: BtcRestoreMode

    init(blockchain: Blockchain, btcBlockchainManager: BtcBlockchainManager) {
        self.blockchain = blockchain
        self.btcBlockchainManager = btcBlockchainManager

        currentRestoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
    }

}

extension BtcBlockchainSettingsService {

    func save(restoreMode: BtcRestoreMode) {
        btcBlockchainManager.save(restoreMode: restoreMode, blockchainType: blockchain.type)
    }

}

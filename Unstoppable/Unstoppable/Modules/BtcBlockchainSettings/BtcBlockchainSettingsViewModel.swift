import Combine
import MarketKit

class BtcBlockchainSettingsViewModel: ObservableObject {
    private let btcBlockchainManager = Core.shared.btcBlockchainManager

    let blockchain: Blockchain
    let restoreModes: [BtcRestoreMode]
    let currentRestoreMode: BtcRestoreMode

    @Published var selectedRestoreMode: BtcRestoreMode {
        didSet {
            saveEnabled = selectedRestoreMode != currentRestoreMode
        }
    }

    @Published var saveEnabled = false

    init(blockchain: Blockchain) {
        self.blockchain = blockchain

        restoreModes = BtcRestoreMode.allCases.filter { blockchain.type.supports(restoreMode: $0) }
        currentRestoreMode = btcBlockchainManager.restoreMode(blockchainType: blockchain.type)
        selectedRestoreMode = currentRestoreMode
    }
}

extension BtcBlockchainSettingsViewModel {
    func save() {
        btcBlockchainManager.save(restoreMode: selectedRestoreMode, blockchainType: blockchain.type)
        stat(page: .blockchainSettingsBtc, event: .switchBtcSource(chainUid: blockchain.uid, type: selectedRestoreMode))
    }
}

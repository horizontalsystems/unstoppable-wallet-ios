import MarketKit

class EvmAccountRestoreStateManager {
    private let storage: EvmAccountRestoreStateStorage

    init(storage: EvmAccountRestoreStateStorage) {
        self.storage = storage
    }
}

extension EvmAccountRestoreStateManager {

    func isRestored(account: Account, blockchainType: BlockchainType) -> Bool {
        let state = try? storage.evmAccountRestoreState(accountId: account.id, blockchainUid: blockchainType.uid)
        return state?.restored ?? false
    }

    func setRestored(account: Account, blockchainType: BlockchainType) {
        let state = EvmAccountRestoreState(accountId: account.id, blockchainUid: blockchainType.uid, restored: true)
        try? storage.save(evmAccountRestoreState: state)
    }

}

import MarketKit

class RestoreStateManager {
    private let storage: RestoreStateStorage

    init(storage: RestoreStateStorage) {
        self.storage = storage
    }
}

extension RestoreStateManager {
    func restoreState(account: Account, blockchainType: BlockchainType) -> RestoreState {
        (try? storage.restoreState(accountId: account.id, blockchainUid: blockchainType.uid)) ?? RestoreState(accountId: account.id, blockchainUid: blockchainType.uid)
    }

    func shouldRestore(account: Account, blockchainType: BlockchainType) -> Bool {
        restoreState(account: account, blockchainType: blockchainType).shouldRestore
    }

    func initialRestored(account: Account, blockchainType: BlockchainType) -> Bool {
        restoreState(account: account, blockchainType: blockchainType).initialRestored
    }

    func setShouldRestore(account: Account, blockchainType: BlockchainType) {
        var state = (try? storage.restoreState(accountId: account.id, blockchainUid: blockchainType.uid)) ?? RestoreState(accountId: account.id, blockchainUid: blockchainType.uid)
        state.shouldRestore = true
        try? storage.save(restoreState: state)
    }

    func setInitialRestored(account: Account, blockchainType: BlockchainType) {
        var state = (try? storage.restoreState(accountId: account.id, blockchainUid: blockchainType.uid)) ?? RestoreState(accountId: account.id, blockchainUid: blockchainType.uid)
        state.initialRestored = true
        try? storage.save(restoreState: state)
    }
}

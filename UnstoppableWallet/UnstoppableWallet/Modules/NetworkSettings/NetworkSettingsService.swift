import RxSwift
import RxRelay
import EthereumKit

class NetworkSettingsService {
    let account: Account
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmSyncSourceManager: EvmSyncSourceManager
    private let disposeBag = DisposeBag()

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items: [Item] = [] {
        didSet {
            itemsRelay.accept(items)
        }
    }

    init(account: Account, evmBlockchainManager: EvmBlockchainManager, evmSyncSourceManager: EvmSyncSourceManager) {
        self.account = account
        self.evmBlockchainManager = evmBlockchainManager
        self.evmSyncSourceManager = evmSyncSourceManager

        subscribe(disposeBag, evmSyncSourceManager.syncSourceObservable) { [weak self] account, _, _ in self?.handleSettingsUpdated(account: account) }

        syncItems()
    }

    private func handleSettingsUpdated(account: Account) {
        guard account == self.account else {
            return
        }

        syncItems()
    }

    private func syncItems() {
        items = evmBlockchainManager.allBlockchains.map { blockchain in
            Item(
                    blockchain: blockchain,
                    syncSource: evmSyncSourceManager.syncSource(account: account, blockchain: blockchain)
            )
        }
    }

}

extension NetworkSettingsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

}

extension NetworkSettingsService {

    struct Item {
        let blockchain: EvmBlockchain
        let syncSource: EvmSyncSource
    }

}

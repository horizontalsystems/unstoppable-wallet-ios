import EthereumKit
import MarketKit
import HsToolKit

class EvmBlockchainManager {
    private let syncSourceManager: EvmSyncSourceManager
    private let accountManager: IAccountManager
    private let walletManager: WalletManager
    private let coinManager: CoinManager
    private let networkManager: NetworkManager
    private let storage: IEvmAccountSyncStateStorage

    private var evmKitManagerMap = [EvmBlockchain: EvmKitManager]()
    private var evmAccountManagerMap = [EvmBlockchain: EvmAccountManager]()

    init(syncSourceManager: EvmSyncSourceManager, accountManager: IAccountManager, walletManager: WalletManager, coinManager: CoinManager, networkManager: NetworkManager, storage: IEvmAccountSyncStateStorage) {
        self.syncSourceManager = syncSourceManager
        self.accountManager = accountManager
        self.walletManager = walletManager
        self.coinManager = coinManager
        self.networkManager = networkManager
        self.storage = storage
    }

    private func _chain(blockchain: EvmBlockchain) -> Chain {
        switch blockchain {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        case .polygon: return .polygon
        }
    }

}

extension EvmBlockchainManager {

    var allBlockchains: [EvmBlockchain] {
        [
            .ethereum,
            .binanceSmartChain,
            .polygon
        ]

        // todo: load custom blockchains here
    }

    func blockchain(chainId: Int) -> EvmBlockchain? {
        allBlockchains.first(where: { chain(blockchain: $0).id == chainId })
    }

    func blockchain(coinType: CoinType) -> EvmBlockchain? {
        allBlockchains.first(where: { $0.supports(coinType: coinType) })
    }

    func chain(chainId: Int) -> Chain? {
        blockchain(chainId: chainId).map { chain(blockchain: $0) }
    }

    func chain(blockchain: EvmBlockchain) -> Chain {
        evmKitManager(blockchain: blockchain).chain
    }

    func evmKitManager(blockchain: EvmBlockchain) -> EvmKitManager {
        if let manager = evmKitManagerMap[blockchain] {
            return manager
        }

        let manager = EvmKitManager(chain: _chain(blockchain: blockchain), syncSourceManager: syncSourceManager)
        let provider = EnableCoinsEip20Provider(networkManager: networkManager, blockchain: blockchain)
        let evmAccountManager = EvmAccountManager(blockchain: blockchain, accountManager: accountManager, walletManager: walletManager, coinManager: coinManager, syncSourceManager: syncSourceManager, evmKitManager: manager, provider: provider, storage: storage)

        evmKitManagerMap[blockchain] = manager
        evmAccountManagerMap[blockchain] = evmAccountManager

        return manager
    }

    func basePlatformCoin(blockchain: EvmBlockchain) -> PlatformCoin? {
        try? coinManager.platformCoin(coinType: blockchain.baseCoinType)
    }

}

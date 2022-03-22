import EthereumKit
import MarketKit
import HsToolKit

class EvmBlockchainManager {
    private let syncSourceManager: EvmSyncSourceManager
    private let marketKit: MarketKit.Kit
    private let accountManagerFactory: EvmAccountManagerFactory

    private var evmKitManagerMap = [EvmBlockchain: EvmKitManager]()
    private var evmAccountManagerMap = [EvmBlockchain: EvmAccountManager]()

    init(syncSourceManager: EvmSyncSourceManager, marketKit: MarketKit.Kit, accountManagerFactory: EvmAccountManagerFactory) {
        self.syncSourceManager = syncSourceManager
        self.marketKit = marketKit
        self.accountManagerFactory = accountManagerFactory
    }

    private func _chain(blockchain: EvmBlockchain) -> Chain {
        switch blockchain {
        case .ethereum: return .ethereum
        case .binanceSmartChain: return .binanceSmartChain
        case .polygon: return .polygon
        case .optimism: return .optimism
        case .arbitrumOne: return .arbitrumOne
        }
    }

    private func evmManagers(blockchain: EvmBlockchain) -> (EvmKitManager, EvmAccountManager) {
        if let evmKitManager = evmKitManagerMap[blockchain], let evmAccountManager = evmAccountManagerMap[blockchain] {
            return (evmKitManager, evmAccountManager)
        }

        let evmKitManager = EvmKitManager(chain: _chain(blockchain: blockchain), syncSourceManager: syncSourceManager)
        let evmAccountManager = accountManagerFactory.evmAccountManager(blockchain: blockchain, evmKitManager: evmKitManager)

        evmKitManagerMap[blockchain] = evmKitManager
        evmAccountManagerMap[blockchain] = evmAccountManager

        return (evmKitManager, evmAccountManager)
    }

}

extension EvmBlockchainManager {

    var allBlockchains: [EvmBlockchain] {
        [
            .ethereum,
            .binanceSmartChain,
            .polygon,
//            .optimism,
//            .arbitrumOne
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

    func basePlatformCoin(blockchain: EvmBlockchain) -> PlatformCoin? {
        try? marketKit.platformCoin(coinType: blockchain.baseCoinType)
    }

    func evmKitManager(blockchain: EvmBlockchain) -> EvmKitManager {
        evmManagers(blockchain: blockchain).0
    }

    func evmAccountManager(blockchain: EvmBlockchain) -> EvmAccountManager {
        evmManagers(blockchain: blockchain).1
    }

}

import RxSwift
import RxRelay
import EvmKit
import MarketKit

class EvmSyncSourceManager {
    private let appConfigProvider: AppConfigProvider
    private let storage: BlockchainSettingsStorage

    private let syncSourceRelay = PublishRelay<BlockchainType>()
    let infuraRpcSource: RpcSource

    init(appConfigProvider: AppConfigProvider, storage: BlockchainSettingsStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage

        infuraRpcSource = .ethereumInfuraHttp(projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret)
    }

    private func defaultSyncSources(blockchainType: BlockchainType) -> [EvmSyncSource] {
        switch blockchainType {
        case .ethereum:
            return [
                EvmSyncSource(
                        name: "Infura WebSocket",
                        rpcSource: .ethereumInfuraWebsocket(projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret),
                        transactionSource: .ethereumEtherscan(apiKey: appConfigProvider.etherscanKey)
                ),
                EvmSyncSource(
                        name: "Infura HTTP",
                        rpcSource: infuraRpcSource,
                        transactionSource: .ethereumEtherscan(apiKey: appConfigProvider.etherscanKey)
                )
            ]
        case .binanceSmartChain:
            return [
                EvmSyncSource(
                        name: "Default HTTP",
                        rpcSource: .binanceSmartChainHttp(),
                        transactionSource: .bscscan(apiKey: appConfigProvider.bscscanKey)
                ),
                EvmSyncSource(
                        name: "BSC-RPC HTTP",
                        rpcSource: .bscRpcHttp(),
                        transactionSource: .bscscan(apiKey: appConfigProvider.bscscanKey)
                ),
                EvmSyncSource(
                        name: "Default WebSocket",
                        rpcSource: .binanceSmartChainWebSocket(),
                        transactionSource: .bscscan(apiKey: appConfigProvider.bscscanKey)
                )
            ]
        case .polygon:
            return [
                EvmSyncSource(
                        name: "Polygon-RPC HTTP",
                        rpcSource: .polygonRpcHttp(),
                        transactionSource: .polygonscan(apiKey: appConfigProvider.polygonscanKey)
                )
            ]
        case .avalanche:
            return [
                EvmSyncSource(
                        name: "Avax.network HTTP",
                        rpcSource: .avaxNetworkHttp(),
                        transactionSource: .snowtrace(apiKey: appConfigProvider.snowtraceKey)
                )
            ]
        case .optimism:
            return [
                EvmSyncSource(
                        name: "Optimism.io HTTP",
                        rpcSource: .optimismRpcHttp(),
                        transactionSource: .optimisticEtherscan(apiKey: appConfigProvider.optimismEtherscanKey)
                )
            ]
        case .arbitrumOne:
            return [
                EvmSyncSource(
                        name: "Arbitrum.io HTTP",
                        rpcSource: .arbitrumOneRpcHttp(),
                        transactionSource: .arbiscan(apiKey: appConfigProvider.arbiscanKey)
                )
            ]
        default:
            return []
        }
    }

}

extension EvmSyncSourceManager {

    var syncSourceObservable: Observable<BlockchainType> {
        syncSourceRelay.asObservable()
    }

    func allSyncSources(blockchainType: BlockchainType) -> [EvmSyncSource] {
        defaultSyncSources(blockchainType: blockchainType)

        // todo: load custom network from DB
    }

    func syncSource(blockchainType: BlockchainType) -> EvmSyncSource {
        let syncSources = allSyncSources(blockchainType: blockchainType)

        if let name = storage.evmSyncSourceName(blockchainType: blockchainType), let syncSource = syncSources.first(where: { $0.name == name }) {
            return syncSource
        }

        return syncSources[0]
    }

    func save(syncSource: EvmSyncSource, blockchainType: BlockchainType) {
        storage.save(evmSyncSourceName: syncSource.name, blockchainType: blockchainType)
        syncSourceRelay.accept(blockchainType)
    }

}

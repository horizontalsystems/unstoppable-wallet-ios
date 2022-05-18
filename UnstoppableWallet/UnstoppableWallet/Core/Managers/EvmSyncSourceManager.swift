import RxSwift
import RxRelay
import EthereumKit

class EvmSyncSourceManager {
    private let appConfigProvider: AppConfigProvider
    private let storage: BlockchainSettingsStorage

    private let syncSourceRelay = PublishRelay<EvmBlockchain>()
    let infuraRpcSource: RpcSource

    init(appConfigProvider: AppConfigProvider, storage: BlockchainSettingsStorage) {
        self.appConfigProvider = appConfigProvider
        self.storage = storage

        infuraRpcSource = .ethereumInfuraHttp(projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret)
    }

    private func defaultSyncSources(blockchain: EvmBlockchain) -> [EvmSyncSource] {
        switch blockchain {
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
        case .optimism:
            return [
                EvmSyncSource(
                        name: "Optimism.io HTTP",
                        rpcSource: .optimismRpcHttp(),
                        transactionSource: .optimisticEtherscan(apiKey: "")
                )
            ]
        case .arbitrumOne:
            return [
                EvmSyncSource(
                        name: "Arbitrum.io HTTP",
                        rpcSource: .arbitrumOneRpcHttp(),
                        transactionSource: .arbiscan(apiKey: "")
                )
            ]
        }
    }

}

extension EvmSyncSourceManager {

    var syncSourceObservable: Observable<EvmBlockchain> {
        syncSourceRelay.asObservable()
    }

    func allSyncSources(blockchain: EvmBlockchain) -> [EvmSyncSource] {
        defaultSyncSources(blockchain: blockchain)

        // todo: load custom network from DB
    }

    func syncSource(blockchain: EvmBlockchain) -> EvmSyncSource {
        let syncSources = allSyncSources(blockchain: blockchain)

        if let name = storage.evmSyncSourceName(evmBlockchain: blockchain), let syncSource = syncSources.first(where: { $0.name == name }) {
            return syncSource
        }

        return syncSources[0]
    }

    func save(syncSource: EvmSyncSource, blockchain: EvmBlockchain) {
        storage.save(evmSyncSourceName: syncSource.name, evmBlockchain: blockchain)
        syncSourceRelay.accept(blockchain)
    }

}

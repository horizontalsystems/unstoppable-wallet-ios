import RxSwift
import RxRelay
import EthereumKit

class EvmSyncSourceManager {
    private let appConfigProvider: AppConfigProvider
    private let accountSettingManager: AccountSettingManager

    private let syncSourceRelay = PublishRelay<(Account, EvmBlockchain, EvmSyncSource)>()

    init(appConfigProvider: AppConfigProvider, accountSettingManager: AccountSettingManager) {
        self.appConfigProvider = appConfigProvider
        self.accountSettingManager = accountSettingManager
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
                        rpcSource: .ethereumInfuraHttp(projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret),
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
        }
    }

}

extension EvmSyncSourceManager {

    var syncSourceObservable: Observable<(Account, EvmBlockchain, EvmSyncSource)> {
        syncSourceRelay.asObservable()
    }

    func allSyncSources(blockchain: EvmBlockchain) -> [EvmSyncSource] {
        defaultSyncSources(blockchain: blockchain)

        // todo: load custom network from DB
    }

    func syncSource(account: Account, blockchain: EvmBlockchain) -> EvmSyncSource {
        let syncSources = allSyncSources(blockchain: blockchain)

        if let name = accountSettingManager.evmSyncSourceName(account: account, blockchain: blockchain), let syncSource = syncSources.first(where: { $0.name == name }) {
            return syncSource
        }

        return syncSources[0]
    }

    func save(syncSource: EvmSyncSource, account: Account, blockchain: EvmBlockchain) {
        accountSettingManager.save(evmSyncSourceName: syncSource.name, account: account, blockchain: blockchain)
        syncSourceRelay.accept((account, blockchain, syncSource))
    }

}

import Foundation
import RxSwift
import RxRelay
import EvmKit
import MarketKit

class EvmSyncSourceManager {
    private let appConfigProvider: AppConfigProvider
    private let testNetManager: TestNetManager
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let evmSyncSourceStorage: EvmSyncSourceStorage

    private let syncSourceRelay = PublishRelay<BlockchainType>()
    private let syncSourcesUpdatedRelay = PublishRelay<BlockchainType>()

    init(appConfigProvider: AppConfigProvider, testNetManager: TestNetManager, blockchainSettingsStorage: BlockchainSettingsStorage, evmSyncSourceStorage: EvmSyncSourceStorage) {
        self.appConfigProvider = appConfigProvider
        self.testNetManager = testNetManager
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.evmSyncSourceStorage = evmSyncSourceStorage
    }

    private func defaultTransactionSource(blockchainType: BlockchainType) -> EvmKit.TransactionSource {
        switch blockchainType {
        case .ethereum: return .ethereumEtherscan(apiKey: appConfigProvider.etherscanKey)
        case .binanceSmartChain: return .bscscan(apiKey: appConfigProvider.bscscanKey)
        case .polygon: return .polygonscan(apiKey: appConfigProvider.polygonscanKey)
        case .avalanche: return .snowtrace(apiKey: appConfigProvider.snowtraceKey)
        case .optimism: return .optimisticEtherscan(apiKey: appConfigProvider.optimismEtherscanKey)
        case .arbitrumOne: return .arbiscan(apiKey: appConfigProvider.arbiscanKey)
        case .gnosis: return .gnosis(apiKey: appConfigProvider.gnosisscanKey)
        case .fantom: return .fantom(apiKey: appConfigProvider.ftmscanKey)
        default: fatalError("Non-supported EVM blockchain")
        }
    }

}

extension EvmSyncSourceManager {

    var syncSourceObservable: Observable<BlockchainType> {
        syncSourceRelay.asObservable()
    }

    var syncSourcesUpdatedObservable: Observable<BlockchainType> {
        syncSourcesUpdatedRelay.asObservable()
    }

    func defaultSyncSources(blockchainType: BlockchainType) -> [EvmSyncSource] {
        switch blockchainType {
        case .ethereum:
            if testNetManager.testNetEnabled {
                return [
                    EvmSyncSource(
                            name: "Infura Sepolia",
                            rpcSource: .http(urls: [URL(string: "https://sepolia.infura.io/v3/\(appConfigProvider.infuraCredentials.id)")!], auth: appConfigProvider.infuraCredentials.secret),
                            transactionSource: EvmKit.TransactionSource(
                                    name: "sepolia.etherscan.io",
                                    type: .etherscan(apiBaseUrl: "https://api-sepolia.etherscan.io", txBaseUrl: "https://sepiloa.etherscan.io", apiKey: appConfigProvider.etherscanKey)
                            )
                    )
                ]
            } else {
                return [
                    EvmSyncSource(
                            name: "Infura",
                            rpcSource: .ethereumInfuraWebsocket(projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret),
                            transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
                    EvmSyncSource(
                            name: "Infura",
                            rpcSource: .ethereumInfuraHttp(projectId: appConfigProvider.infuraCredentials.id, projectSecret: appConfigProvider.infuraCredentials.secret),
                            transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
                    EvmSyncSource(
                            name: "LlamaNodes",
                            rpcSource: .http(urls: [URL(string: "https://eth.llamarpc.com")!], auth: nil),
                            transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    )
                ]
            }
        case .binanceSmartChain:
            if testNetManager.testNetEnabled {
                return [
                    EvmSyncSource(
                            name: "Binance TestNet",
                            rpcSource: .http(urls: [URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545")!], auth: nil),
                            transactionSource: EvmKit.TransactionSource(
                                    name: "testnet.bscscan.com",
                                    type: .etherscan(apiBaseUrl: "https://api-testnet.bscscan.com", txBaseUrl: "https://testnet.bscscan.com", apiKey: appConfigProvider.bscscanKey)
                            )
                    )
                ]
            } else {
                return [
                    EvmSyncSource(
                            name: "Binance",
                            rpcSource: .binanceSmartChainHttp(),
                            transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
                    EvmSyncSource(
                            name: "BSC RPC",
                            rpcSource: .bscRpcHttp(),
                            transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
                    EvmSyncSource(
                            name: "Omnia",
                            rpcSource: .http(urls: [URL(string: "https://endpoints.omniatech.io/v1/bsc/mainnet/public")!], auth: nil),
                            transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    )
                ]
            }
        case .polygon:
            return [
                EvmSyncSource(
                        name: "Polygon RPC",
                        rpcSource: .polygonRpcHttp(),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                ),
                EvmSyncSource(
                        name: "LlamaNodes",
                        rpcSource: .http(urls: [URL(string: "https://polygon.llamarpc.com")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            ]
        case .avalanche:
            return [
                EvmSyncSource(
                        name: "Avax Network",
                        rpcSource: .avaxNetworkHttp(),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                ),
                EvmSyncSource(
                        name: "PublicNode",
                        rpcSource: .http(urls: [URL(string: "https://avalanche-evm.publicnode.com")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            ]
        case .optimism:
            return [
                EvmSyncSource(
                        name: "Optimism",
                        rpcSource: .optimismRpcHttp(),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                ),
                EvmSyncSource(
                        name: "Omnia",
                        rpcSource: .http(urls: [URL(string: "https://endpoints.omniatech.io/v1/op/mainnet/public")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            ]
        case .arbitrumOne:
            return [
                EvmSyncSource(
                        name: "Arbitrum",
                        rpcSource: .arbitrumOneRpcHttp(),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                ),
                EvmSyncSource(
                        name: "Omnia",
                        rpcSource: .http(urls: [URL(string: "https://endpoints.omniatech.io/v1/arbitrum/one/public")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            ]
        case .gnosis:
            return [
                EvmSyncSource(
                        name: "Gnosis Chain",
                        rpcSource: .gnosisRpcHttp(),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                ),
                EvmSyncSource(
                        name: "Ankr",
                        rpcSource: .http(urls: [URL(string: "https://rpc.ankr.com/gnosis")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            ]
        case .fantom:
            return [
                EvmSyncSource(
                        name: "Fantom Chain",
                        rpcSource: .fantomRpcHttp(),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                ),
                EvmSyncSource(
                        name: "Ankr",
                        rpcSource: .http(urls: [URL(string: "https://rpc.ankr.com/fantom")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            ]
        default:
            return []
        }
    }

    func customSyncSources(blockchainType: BlockchainType) -> [EvmSyncSource] {
        do {
            let records = try evmSyncSourceStorage.records(blockchainTypeUid: blockchainType.uid)

            return records.compactMap { record in
                guard let url = URL(string: record.url), let scheme = url.scheme else {
                    return nil
                }

                let rpcSource: RpcSource

                switch scheme {
                case "http", "https": rpcSource = .http(urls: [url], auth: record.auth)
                case "ws", "wss": rpcSource = .webSocket(url: url, auth: record.auth)
                default: return nil
                }

                return EvmSyncSource(
                        name: url.host ?? "",
                        rpcSource: rpcSource,
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                )
            }
        } catch {
            return []
        }
    }

    func allSyncSources(blockchainType: BlockchainType) -> [EvmSyncSource] {
        defaultSyncSources(blockchainType: blockchainType) + customSyncSources(blockchainType: blockchainType)
    }

    func syncSource(blockchainType: BlockchainType) -> EvmSyncSource {
        let syncSources = allSyncSources(blockchainType: blockchainType)

        if let urlString = blockchainSettingsStorage.evmSyncSourceUrl(blockchainType: blockchainType),
           let syncSource = syncSources.first(where: { $0.rpcSource.url.absoluteString == urlString }) {
            return syncSource
        }

        return syncSources[0]
    }

    func httpSyncSource(blockchainType: BlockchainType) -> EvmSyncSource? {
        let syncSources = allSyncSources(blockchainType: blockchainType)

        if let urlString = blockchainSettingsStorage.evmSyncSourceUrl(blockchainType: blockchainType),
           let syncSource = syncSources.first(where: { $0.rpcSource.url.absoluteString == urlString }), syncSource.isHttp {
            return syncSource
        }

        return syncSources.first { $0.isHttp }
    }

    func saveCurrent(syncSource: EvmSyncSource, blockchainType: BlockchainType) {
        blockchainSettingsStorage.save(evmSyncSourceUrl: syncSource.rpcSource.url.absoluteString, blockchainType: blockchainType)
        syncSourceRelay.accept(blockchainType)
    }

    func saveSyncSource(blockchainType: BlockchainType, url: URL, auth: String?) {
        let record = EvmSyncSourceRecord(
                blockchainTypeUid: blockchainType.uid,
                url: url.absoluteString,
                auth: auth
        )

        try? evmSyncSourceStorage.save(record: record)

        if let syncSource = customSyncSources(blockchainType: blockchainType).first(where: { $0.rpcSource.url == url }) {
            saveCurrent(syncSource: syncSource, blockchainType: blockchainType)
        }

        syncSourcesUpdatedRelay.accept(blockchainType)
    }

    func delete(syncSource: EvmSyncSource, blockchainType: BlockchainType) {
        let isCurrent = self.syncSource(blockchainType: blockchainType) == syncSource

        try? evmSyncSourceStorage.delete(blockchainTypeUid: blockchainType.uid, url: syncSource.rpcSource.url.absoluteString)

        if isCurrent {
            syncSourceRelay.accept(blockchainType)
        }

        syncSourcesUpdatedRelay.accept(blockchainType)
    }

}

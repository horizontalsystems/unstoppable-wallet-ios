import EvmKit
import Foundation
import MarketKit
import RxRelay
import RxSwift

class EvmSyncSourceManager {
    private let testNetManager: TestNetManager
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let evmSyncSourceStorage: EvmSyncSourceStorage

    private let syncSourceRelay = PublishRelay<BlockchainType>()
    private let syncSourcesUpdatedRelay = PublishRelay<BlockchainType>()

    init(testNetManager: TestNetManager, blockchainSettingsStorage: BlockchainSettingsStorage, evmSyncSourceStorage: EvmSyncSourceStorage) {
        self.testNetManager = testNetManager
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.evmSyncSourceStorage = evmSyncSourceStorage
    }

    private func defaultTransactionSource(blockchainType: BlockchainType) -> EvmKit.TransactionSource {
        switch blockchainType {
        case .ethereum: return .ethereumEtherscan(apiKey: AppConfig.etherscanKey)
        case .binanceSmartChain: return .bscscan(apiKey: AppConfig.bscscanKey)
        case .polygon: return .polygonscan(apiKey: AppConfig.polygonscanKey)
        case .avalanche: return .snowtrace(apiKey: AppConfig.snowtraceKey)
        case .optimism: return .optimisticEtherscan(apiKey: AppConfig.optimismEtherscanKey)
        case .arbitrumOne: return .arbiscan(apiKey: AppConfig.arbiscanKey)
        case .gnosis: return .gnosis(apiKey: AppConfig.gnosisscanKey)
        case .fantom: return .fantom(apiKey: AppConfig.ftmscanKey)
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
                        rpcSource: .http(urls: [URL(string: "https://sepolia.infura.io/v3/\(AppConfig.infuraCredentials.id)")!], auth: AppConfig.infuraCredentials.secret),
                        transactionSource: EvmKit.TransactionSource(
                            name: "sepolia.etherscan.io",
                            type: .etherscan(apiBaseUrl: "https://api-sepolia.etherscan.io", txBaseUrl: "https://sepiloa.etherscan.io", apiKey: AppConfig.etherscanKey)
                        )
                    ),
                ]
            } else {
                return [
                    EvmSyncSource(
                        name: "Infura",
                        rpcSource: .ethereumInfuraWebsocket(projectId: AppConfig.infuraCredentials.id, projectSecret: AppConfig.infuraCredentials.secret),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
                    EvmSyncSource(
                        name: "Infura",
                        rpcSource: .ethereumInfuraHttp(projectId: AppConfig.infuraCredentials.id, projectSecret: AppConfig.infuraCredentials.secret),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
                    EvmSyncSource(
                        name: "LlamaNodes",
                        rpcSource: .http(urls: [URL(string: "https://eth.llamarpc.com")!], auth: nil),
                        transactionSource: defaultTransactionSource(blockchainType: blockchainType)
                    ),
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
                            type: .etherscan(apiBaseUrl: "https://api-testnet.bscscan.com", txBaseUrl: "https://testnet.bscscan.com", apiKey: AppConfig.bscscanKey)
                        )
                    ),
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
                    ),
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
                ),
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
                ),
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
                ),
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
                ),
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
                ),
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
                ),
            ]
        default:
            return []
        }
    }

    func customSyncSources(blockchainType: BlockchainType?) -> [EvmSyncSource] {
        do {
            let records: [EvmSyncSourceRecord]
            if let blockchainType {
                records = try evmSyncSourceStorage.records(blockchainTypeUid: blockchainType.uid)
            } else {
                records = try evmSyncSourceStorage.getAll()
            }

            return records.compactMap { record in
                let blockchainType = BlockchainType(uid: record.blockchainTypeUid)
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
           let syncSource = syncSources.first(where: { $0.rpcSource.url.absoluteString == urlString })
        {
            return syncSource
        }

        return syncSources[0]
    }

    func httpSyncSource(blockchainType: BlockchainType) -> EvmSyncSource? {
        let syncSources = allSyncSources(blockchainType: blockchainType)

        if let urlString = blockchainSettingsStorage.evmSyncSourceUrl(blockchainType: blockchainType),
           let syncSource = syncSources.first(where: { $0.rpcSource.url.absoluteString == urlString }), syncSource.isHttp
        {
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

extension EvmSyncSourceManager {
    var customSources: [EvmSyncSourceRecord] {
        (try? evmSyncSourceStorage.getAll()) ?? []
    }

    var selectedSources: [SelectedSource] {
        EvmBlockchainManager
            .blockchainTypes
            .map { type in
                SelectedSource(
                    blockchainTypeUid: type.uid,
                    url: syncSource(blockchainType: type).rpcSource.url.absoluteString
                )
            }
    }
}

extension EvmSyncSourceManager {
    func decrypt(sources: [CustomSyncSource], passphrase: String) throws -> [EvmSyncSourceRecord] {
        try sources.map { source in
            let auth = try source.auth
                .flatMap { try $0.decrypt(passphrase: passphrase) }
                .flatMap { String(data: $0, encoding: .utf8) }

            return EvmSyncSourceRecord(
                blockchainTypeUid: source.blockchainTypeUid,
                url: source.url,
                auth: auth
            )
        }
    }

    func encrypt(sources: [EvmSyncSourceRecord], passphrase: String) throws -> [CustomSyncSource] {
        try sources.map { source in
            let crypto = try source.auth
                .flatMap { $0.isEmpty ? nil : $0 }
                .flatMap { $0.data(using: .utf8) }
                .flatMap { try BackupCrypto.encrypt(data: $0, passphrase: passphrase) }

            return CustomSyncSource(
                blockchainTypeUid: source.blockchainTypeUid,
                url: source.url,
                auth: crypto
            )
        }
    }
}

extension EvmSyncSourceManager {
    func restore(selected: [SelectedSource], custom: [EvmSyncSourceRecord]) {
        var blockchainTypes = Set<BlockchainType>()
        custom.forEach { source in
            blockchainTypes.insert(BlockchainType(uid: source.blockchainTypeUid))
            try? evmSyncSourceStorage.save(record: source)
        }

        selected.forEach { source in
            let blockchainType = BlockchainType(uid: source.blockchainTypeUid)
            if let syncSource = allSyncSources(blockchainType: blockchainType)
                .first(where: { $0.rpcSource.url.absoluteString == source.url })
            {
                saveCurrent(syncSource: syncSource, blockchainType: blockchainType)
            }
        }

        blockchainTypes.forEach { blockchainType in
            syncSourcesUpdatedRelay.accept(blockchainType)
        }
    }
}

extension EvmSyncSourceManager {
    struct SelectedSource: Codable {
        let blockchainTypeUid: String
        let url: String

        enum CodingKeys: String, CodingKey {
            case blockchainTypeUid = "blockchain_type_id"
            case url
        }
    }

    struct CustomSyncSource: Codable {
        let blockchainTypeUid: String
        let url: String
        let auth: BackupCrypto?

        enum CodingKeys: String, CodingKey {
            case blockchainTypeUid = "blockchain_type_id"
            case url
            case auth
        }
    }

    struct SyncSourceBackup: Codable {
        let selected: [SelectedSource]
        let custom: [CustomSyncSource]
    }
}

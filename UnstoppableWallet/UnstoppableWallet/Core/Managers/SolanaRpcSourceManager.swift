import Foundation
import MarketKit
import RxRelay
import RxSwift
import SolanaKit

class SolanaRpcSourceManager {
    private let blockchainSettingsStorage: BlockchainSettingsStorage
    private let marketKit: MarketKit.Kit

    private let rpcSourceRelay = PublishRelay<Void>()

    init(blockchainSettingsStorage: BlockchainSettingsStorage, marketKit: MarketKit.Kit) {
        self.blockchainSettingsStorage = blockchainSettingsStorage
        self.marketKit = marketKit
    }

    var allRpcSources: [SolanaKit.RpcSource] {
        var sources = [SolanaKit.RpcSource]()
        if let apiKey = AppConfig.solanaAlchemyApiKey {
            sources.append(.alchemy(apiKey: apiKey))
        }
        sources.append(.mainnetBeta())
        return sources
    }

    var rpcSource: SolanaKit.RpcSource {
        let savedName = blockchainSettingsStorage.evmSyncSourceUrl(blockchainType: .solana)
        return allRpcSources.first { $0.name == savedName } ?? allRpcSources[0]
    }

    func save(rpcSource: SolanaKit.RpcSource) {
        blockchainSettingsStorage.save(evmSyncSourceUrl: rpcSource.name, blockchainType: .solana)
        rpcSourceRelay.accept(())
    }

    var rpcSourceObservable: Observable<Void> {
        rpcSourceRelay.asObservable()
    }

    var blockchain: Blockchain? {
        try? marketKit.blockchain(uid: BlockchainType.solana.uid)
    }
}

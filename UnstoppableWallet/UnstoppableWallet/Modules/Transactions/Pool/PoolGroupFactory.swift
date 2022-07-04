import Foundation
import RxSwift
import MarketKit

class PoolGroupFactory {

    private func providers(wallets: [Wallet], blockchainType: BlockchainType?, filter: TransactionTypeFilter, configuredToken: ConfiguredToken?) -> [PoolProvider] {
        if let configuredToken = configuredToken {
            let poolSource = PoolSource(
                    blockchainType: configuredToken.token.blockchainType,
                    filter: filter,
                    configuredToken: configuredToken,
                    bep2Symbol: configuredToken.token.type.bep2Symbol
            )

            if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                let provider = PoolProvider(adapter: adapter, source: poolSource)
                return [provider]
            }
        } else if let blockchainType = blockchainType {
            if App.shared.evmBlockchainManager.allBlockchains.contains(where: { $0.type == blockchainType }) {
                let poolSource = PoolSource(
                        blockchainType: blockchainType,
                        filter: filter,
                        configuredToken: nil,
                        bep2Symbol: nil
                )

                if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                    let provider = PoolProvider(adapter: adapter, source: poolSource)
                    return [provider]
                }
            } else {
                var providers = [PoolProvider]()
                for wallet in wallets {
                    guard wallet.token.blockchainType == blockchainType else {
                        continue
                    }

                    let poolSource = PoolSource(
                            blockchainType: blockchainType,
                            filter: filter,
                            configuredToken: wallet.configuredToken,
                            bep2Symbol: wallet.token.type.bep2Symbol
                    )

                    if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                        let provider = PoolProvider(adapter: adapter, source: poolSource)
                        providers.append(provider)
                    }
                }
                return providers
            }
        } else {
            var poolSources = Set<PoolSource>()

            for wallet in wallets {
                let poolSource: PoolSource

                if App.shared.evmBlockchainManager.allBlockchains.contains(where: { $0 == wallet.token.blockchain }) {
                    poolSource = PoolSource(
                            blockchainType: wallet.token.blockchainType,
                            filter: filter,
                            configuredToken: nil,
                            bep2Symbol: nil
                    )
                } else {
                    poolSource = PoolSource(
                            blockchainType: wallet.token.blockchainType,
                            filter: filter,
                            configuredToken: wallet.configuredToken,
                            bep2Symbol: wallet.token.type.bep2Symbol
                    )
                }

                poolSources.insert(poolSource)
            }

            return poolSources.compactMap { poolSource in
                if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                    return PoolProvider(adapter: adapter, source: poolSource)
                } else {
                    return nil
                }
            }
        }

        return []
    }

}

extension PoolGroupFactory {

    func poolGroup(wallets: [Wallet], blockchainType: BlockchainType?, filter: TransactionTypeFilter, configuredToken: ConfiguredToken?) -> PoolGroup {
        let providers = providers(wallets: wallets, blockchainType: blockchainType, filter: filter, configuredToken: configuredToken)
        return PoolGroup(pools: providers.map { Pool(provider: NonSpamPoolProvider(poolProvider: $0)) })
    }

}

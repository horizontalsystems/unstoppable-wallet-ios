import Foundation
import RxSwift
import MarketKit

class PoolGroupFactory {

    private func providers(poolGroupType: PoolGroupType, filter: TransactionTypeFilter) -> [PoolProvider] {
        switch poolGroupType {
        case .all(let wallets):
            var poolSources = Set<PoolSource>()

            for wallet in wallets {
                let poolSource: PoolSource

                if App.shared.evmBlockchainManager.allBlockchains.contains(where: { $0 == wallet.token.blockchain }) || wallet.token.blockchainType == .tron {
                    poolSource = PoolSource(
                            token: nil,
                            blockchainType: wallet.token.blockchainType,
                            filter: filter
                    )
                } else {
                    poolSource = PoolSource(
                            token: wallet.token,
                            blockchainType: wallet.token.blockchainType,
                            filter: filter
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

        case .blockchain(let blockchainType, let wallets):
            if App.shared.evmBlockchainManager.allBlockchains.contains(where: { $0.type == blockchainType }) || blockchainType == .tron {
                let poolSource = PoolSource(
                        token: nil,
                        blockchainType: blockchainType,
                        filter: filter
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
                            token: wallet.token,
                            blockchainType: blockchainType,
                            filter: filter
                    )

                    if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                        let provider = PoolProvider(adapter: adapter, source: poolSource)
                        providers.append(provider)
                    }
                }
                return providers
            }

        case .token(let token):
            let poolSource = PoolSource(
                    token: token,
                    blockchainType: token.blockchainType,
                    filter: filter
            )

            if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                let provider = PoolProvider(adapter: adapter, source: poolSource)
                return [provider]
            }
        }

        return []
    }

}

extension PoolGroupFactory {

    func poolGroup(type: PoolGroupType, filter: TransactionTypeFilter) -> PoolGroup {
        let providers = providers(poolGroupType: type, filter: filter)
        return PoolGroup(pools: providers.map { Pool(provider: NonSpamPoolProvider(poolProvider: $0)) })
    }

}

extension PoolGroupFactory {

    enum PoolGroupType {
        case all(wallets: [Wallet])
        case blockchain(blockchainType: BlockchainType, wallets: [Wallet])
        case token(token: Token)
    }

}

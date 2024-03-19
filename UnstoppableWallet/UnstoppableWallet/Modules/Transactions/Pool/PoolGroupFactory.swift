import Foundation
import MarketKit
import RxSwift

class PoolGroupFactory {
    private func providers(poolGroupType: PoolGroupType, filter: TransactionTypeFilter, contact: Contact?) -> [PoolProvider] {
        switch poolGroupType {
        case let .all(wallets):
            var poolSources = Set<PoolSource>()

            for wallet in wallets {
                // filter by contact, but contact don't have address for blockchainType
                let address = contact?.address(blockchainUid: wallet.token.blockchainType.uid)?.address
                if contact != nil, address == nil {
                    continue
                }

                let poolSource: PoolSource
                if App.shared.evmBlockchainManager.allBlockchains.contains(where: { $0 == wallet.token.blockchain }) || wallet.token.blockchainType == .tron {
                    poolSource = PoolSource(
                        token: nil,
                        blockchainType: wallet.token.blockchainType,
                        filter: filter,
                        address: address
                    )
                } else {
                    poolSource = PoolSource(
                        token: wallet.token,
                        blockchainType: wallet.token.blockchainType,
                        filter: filter,
                        address: address
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

        case let .blockchain(blockchainType, wallets):
            // filter by contact, but contact don't have address for blockchainType
            let address = contact?.address(blockchainUid: blockchainType.uid)?.address
            if contact != nil, address == nil {
                return []
            }
            if App.shared.evmBlockchainManager.allBlockchains.contains(where: { $0.type == blockchainType }) || blockchainType == .tron {
                let poolSource = PoolSource(
                    token: nil,
                    blockchainType: blockchainType,
                    filter: filter,
                    address: address
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
                        filter: filter,
                        address: address
                    )

                    if let adapter = App.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                        let provider = PoolProvider(adapter: adapter, source: poolSource)
                        providers.append(provider)
                    }
                }
                return providers
            }

        case let .token(token):
            // filter by contact, but contact don't have address for blockchainType
            let address = contact?.address(blockchainUid: token.blockchainType.uid)?.address
            if contact != nil, address == nil {
                return []
            }

            let poolSource = PoolSource(
                token: token,
                blockchainType: token.blockchainType,
                filter: filter,
                address: address
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
    func poolGroup(type: PoolGroupType, filter: TransactionTypeFilter, contact: Contact?, scamFilterEnabled: Bool) -> PoolGroup {
        let providers = providers(poolGroupType: type, filter: filter, contact: contact)
        let pools = providers.map { poolProvider in
            scamFilterEnabled ? Pool(provider: NonSpamPoolProvider(poolProvider: poolProvider)) : Pool(provider: poolProvider)
        }
        return PoolGroup(pools: pools)
    }
}

extension PoolGroupFactory {
    enum PoolGroupType {
        case all(wallets: [Wallet])
        case blockchain(blockchainType: BlockchainType, wallets: [Wallet])
        case token(token: Token)
    }
}

import Foundation
import MarketKit
import RxSwift

public class PoolGroupFactory {
    public init() {}

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
                if Core.shared.evmBlockchainManager.allBlockchains.contains(where: { $0 == wallet.token.blockchain }) || wallet.token.blockchainType == .tron || wallet.token.blockchainType == .ton || wallet.token.blockchainType == .stellar || wallet.token.blockchainType == .xrp || wallet.token.blockchainType == .near {
                    poolSource = PoolSource(
                        token: nil,
                        account: wallet.account,
                        blockchainType: wallet.token.blockchainType,
                        filter: filter,
                        address: address
                    )
                } else {
                    poolSource = PoolSource(
                        token: wallet.token,
                        account: wallet.account,
                        blockchainType: wallet.token.blockchainType,
                        filter: filter,
                        address: address
                    )
                }

                poolSources.insert(poolSource)
            }

            return poolSources.compactMap { poolSource in
                if let adapter = Core.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
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
            if Core.shared.evmBlockchainManager.allBlockchains.contains(where: { $0.type == blockchainType }) || blockchainType == .tron || blockchainType == .ton || blockchainType == .stellar || blockchainType == .xrp || blockchainType == .near {
                let accounts = Set(wallets.filter { $0.token.blockchainType == blockchainType }.map(\.account))

                return accounts.compactMap { account in
                    let poolSource = PoolSource(
                        token: nil,
                        account: account,
                        blockchainType: blockchainType,
                        filter: filter,
                        address: address
                    )

                    guard let adapter = Core.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) else {
                        return nil
                    }

                    return PoolProvider(adapter: adapter, source: poolSource)
                }
            } else {
                var providers = [PoolProvider]()
                for wallet in wallets {
                    guard wallet.token.blockchainType == blockchainType else {
                        continue
                    }

                    let poolSource = PoolSource(
                        token: wallet.token,
                        account: wallet.account,
                        blockchainType: blockchainType,
                        filter: filter,
                        address: address
                    )

                    if let adapter = Core.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                        let provider = PoolProvider(adapter: adapter, source: poolSource)
                        providers.append(provider)
                    }
                }
                return providers
            }

        case let .tokens(tokens, accounts):
            var poolSources = Set<PoolSource>()

            for token in tokens {
                // filter by contact, but contact don't have address for blockchainType
                let address = contact?.address(blockchainUid: token.blockchainType.uid)?.address
                if contact != nil, address == nil {
                    continue
                }

                // a token in an account without its wallet has no adapter and drops out below
                for account in accounts {
                    let poolSource = PoolSource(
                        token: token,
                        account: account,
                        blockchainType: token.blockchainType,
                        filter: filter,
                        address: address
                    )

                    poolSources.insert(poolSource)
                }
            }

            return poolSources.compactMap { poolSource in
                if let adapter = Core.shared.transactionAdapterManager.adapter(for: poolSource.transactionSource) {
                    return PoolProvider(adapter: adapter, source: poolSource)
                } else {
                    return nil
                }
            }
        }

        return []
    }
}

public extension PoolGroupFactory {
    func poolGroup(type: PoolGroupType, filter: TransactionTypeFilter, contact: Contact?, scamFilterEnabled: Bool) -> PoolGroup {
        let providers = providers(poolGroupType: type, filter: filter, contact: contact)
        let pools = providers.map { poolProvider in
            scamFilterEnabled ? Pool(provider: NonSpamPoolProvider(poolProvider: poolProvider)) : Pool(provider: poolProvider)
        }
        return PoolGroup(pools: pools)
    }
}

public extension PoolGroupFactory {
    enum PoolGroupType {
        case all(wallets: [Wallet])
        case blockchain(blockchainType: BlockchainType, wallets: [Wallet])
        case tokens(tokens: [Token], accounts: [Account])
    }
}

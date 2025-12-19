import EvmKit
import Foundation
import MarketKit

struct ManageWalletsTokenFetcher {
    private let marketKit = Core.shared.marketKit

    private func tokenQueries(account: Account) -> [TokenQuery] {
        switch account.type {
        case .hdExtendedKey:
            return BtcBlockchainManager.blockchainTypes.flatMap(\.nativeTokenQueries)
        default:
            return BlockchainType.supported.map(\.defaultTokenQuery)
        }
    }

    private func featuredTokens(account: Account) throws -> [Token] {
        let queries = tokenQueries(account: account)
        return try marketKit.tokens(queries: queries)
    }

    private func tokensByAddress(_ address: String) throws -> [Token] {
        try marketKit.tokens(reference: address)
    }

    private func tokensBySearch(_ filter: String, allowedBlockchainTypes: [BlockchainType]? = nil) throws -> [Token] {
        let fullCoins = try marketKit.fullCoins(filter: filter, limit: 100, allowedBlockchainTypes: allowedBlockchainTypes)
        return fullCoins.flatMap(\.tokens)
    }
}

extension ManageWalletsTokenFetcher {
    func fetch(filter: String, account: Account, preferredTokens: [Token], allowedBlockchainTypes: [BlockchainType]? = nil) -> [Token] {
        let trimmed = filter.trimmingCharacters(in: .whitespaces)

        do {
            let tokens: [Token]

            if trimmed.isEmpty {
                let featured = try featuredTokens(account: account)
                let supported = featured.filter { account.type.supports(token: $0) }
                tokens = (preferredTokens + supported)
                    .filter {
                        guard let allowedBlockchainTypes else {
                            return true
                        }
                        return allowedBlockchainTypes.contains($0.blockchainType)
                    }
                    .removeDuplicates()
            } else if let evmAddress = try? EvmKit.Address(hex: trimmed) {
                let fetched = try tokensByAddress(evmAddress.hex)
                tokens = fetched
                    .filter {
                        account.type.supports(token: $0)
                    }
                    .filter {
                        guard let allowedBlockchainTypes else {
                            return true
                        }
                        return allowedBlockchainTypes.contains($0.blockchainType)
                    }
            } else {
                let fetched = try tokensBySearch(trimmed, allowedBlockchainTypes: allowedBlockchainTypes)
                tokens = fetched.filter { account.type.supports(token: $0) }
            }

            return tokens
        } catch {
            return []
        }
    }
}

import MarketKit

// Single source of truth for v1 stablecoin tokens supported by the AA flow:
//   • CreateSmartAccountService reads `v1TokenQueries` to enable wallets at AA creation.
//   • AccountType.passkeyOwned.supports(token:) delegates to `supports(blockchainType:tokenAddress:)`
//     so the gate matches the registry entries exactly.
//
// To add a new (chain, token) pair: append an Entry below — both consumers update automatically.
// NOTE: a (chain, token) pair only becomes truly usable once `ChainAddresses.aa(for:)` returns a
// non-nil value for that chain (Barz facets must be deployed) AND the chain is included in
// `CreateSmartAccountService.v1BlockchainTypes` so a deployment record gets created.
enum StablecoinRegistry {
    private struct Entry {
        let blockchainType: BlockchainType
        let address: String // lowercased for case-insensitive equality
    }

    private static let entries: [Entry] = [
        Entry(blockchainType: .ethereum, address: "0xdac17f958d2ee523a2206206994597c13d831ec7"), // USDT
        Entry(blockchainType: .ethereum, address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"), // USDC
        Entry(blockchainType: .ethereum, address: "0x6b175474e89094c44da98b954eedeac495271d0f"), // DAI
        Entry(blockchainType: .binanceSmartChain, address: "0x55d398326f99059ff775485246999027b3197955"), // USDT
        Entry(blockchainType: .base, address: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"), // USDC
        Entry(blockchainType: .base, address: "0xfde4c96c8593536e31f229ea8f37b2ada2699bb2"), // USDT
        Entry(blockchainType: .base, address: "0x50c5725949a6f0c72e6c4a641f24049a917db0cb"), // DAI
    ]

    static var v1TokenQueries: [TokenQuery] {
        entries.map { TokenQuery(blockchainType: $0.blockchainType, tokenType: .eip20(address: $0.address)) }
    }

    static func supports(blockchainType: BlockchainType, tokenAddress: String) -> Bool {
        let normalized = tokenAddress.lowercased()
        return entries.contains { $0.blockchainType == blockchainType && $0.address == normalized }
    }
}

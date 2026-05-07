import MarketKit

// Single source of truth for v1 stablecoin tokens supported by the gas-abstraction flow:
//   • CreateSmartAccountService reads `v1TokenQueries` to enable wallets at AA creation/restore.
//   • AccountType.passkeyOwned.supports(token:) delegates to `supports(blockchainType:tokenAddress:)`
//     so the gate matches the registry entries exactly.
//
// Two vehicles, one registry:
//   • EVM (ethereum / binanceSmartChain / base): ERC-4337 Barz wallet. A (chain, token) pair is
//     usable once `ChainAddresses.aa(for:)` returns non-nil AND the chain is in
//     `CreateSmartAccountService.v1BlockchainTypes` (so a SmartAccountDeployment record is created).
//   • Tron: GasFree wallet (open.gasfree.io). Tron is NOT in `v1BlockchainTypes` and has no Barz
//     deployment — `GasFreeProfile` is created separately by `SmartAccountManager.createGasFreeProfile`.
//
// To add a new (chain, token) pair: append an Entry below — both consumers update automatically.
enum StablecoinRegistry {
    private struct Entry {
        let blockchainType: BlockchainType
        // Stored in canonical form: lowercased hex for EVM, mixed-case Base58 for Tron.
        // `supports(...)` compares case-insensitively so EVM EIP-55 input still matches.
        let address: String
    }

    private static let entries: [Entry] = [
        Entry(blockchainType: .ethereum, address: "0xdac17f958d2ee523a2206206994597c13d831ec7"), // USDT
        Entry(blockchainType: .ethereum, address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"), // USDC
        Entry(blockchainType: .ethereum, address: "0x6b175474e89094c44da98b954eedeac495271d0f"), // DAI
        Entry(blockchainType: .binanceSmartChain, address: "0x55d398326f99059ff775485246999027b3197955"), // USDT
        Entry(blockchainType: .base, address: "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913"), // USDC
        Entry(blockchainType: .base, address: "0xfde4c96c8593536e31f229ea8f37b2ada2699bb2"), // USDT
        Entry(blockchainType: .base, address: "0x50c5725949a6f0c72e6c4a641f24049a917db0cb"), // DAI
        Entry(blockchainType: .tron, address: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"), // USDT (TRC20, GasFree)
    ]

    static var v1TokenQueries: [TokenQuery] {
        entries.map { TokenQuery(blockchainType: $0.blockchainType, tokenType: .eip20(address: $0.address)) }
    }

    static func supports(blockchainType: BlockchainType, tokenAddress: String) -> Bool {
        entries.contains { entry in
            entry.blockchainType == blockchainType
                && entry.address.caseInsensitiveCompare(tokenAddress) == .orderedSame
        }
    }
}

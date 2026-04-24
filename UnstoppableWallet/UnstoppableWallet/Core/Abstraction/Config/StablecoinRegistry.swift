import MarketKit

// Single source of truth for v1 stablecoin token queries used across AA creation + paymaster
// integration. Part 13 will expand this with per-provider paymaster metadata (symbol, decimals,
// supported providers) — keep additions here so activation (Part 8) and paymaster selection
// (Part 13) don't drift on hardcoded addresses.
//
// Source: docs/aa-reports/part-0-block-C-stablecoin-matrix.md, confirmed with Pimlico API key
// coverage on 2026-04-22.
enum StablecoinRegistry {
    static let v1TokenQueries: [TokenQuery] = [
        TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: "0xdac17f958d2ee523a2206206994597c13d831ec7")),
        TokenQuery(blockchainType: .ethereum, tokenType: .eip20(address: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48")),
        TokenQuery(blockchainType: .binanceSmartChain, tokenType: .eip20(address: "0x55d398326f99059ff775485246999027b3197955")),
    ]
}

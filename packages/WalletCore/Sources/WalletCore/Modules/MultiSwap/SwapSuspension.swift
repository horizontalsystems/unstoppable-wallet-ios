import Foundation
import MarketKit
import ObjectMapper

/// A scoped restriction published by uswap-server on `GET /v2/providers`.
///
/// Two kinds of provider need this and for different reasons:
///  - Providers uswap-server quotes: it already refuses a suspended request, so honouring the rule
///    here is purely so the user never sees a card that is going to fail.
///  - Providers the APP quotes itself (Uniswap, PancakeSwap, AllBridge, and 1inch/THORChain/Maya,
///    which have native implementations here): no server call happens at all, so this filter is the
///    ONLY enforcement that exists. Dropping it would make those providers unsuspendable.
public struct SwapSuspension: ImmutableMappable {
    public enum Kind: String {
        case asset
        case chain
        case pair
    }

    /// Which side of the swap the rule covers. Provider deposit and payout capability break
    /// independently, so "either side" is a default, not the only option.
    public enum Side: String {
        case any
        case sell
        case buy
    }

    public let kind: Kind
    public let side: Side
    /// The CANONICAL asset ID (`ETH.0XA0B86991…`, `BTC.BTC`, `ETH-ETH`) — an ordinary asset
    /// identifier, the same vocabulary a quote request uses, but exactly ONE spelling per asset.
    ///
    /// The server normalizes here because an asset has several valid identifiers and which one we
    /// send depends on the sub-provider — this app spells USDC `ETH.USDC-0XA0B8…` via the asset map,
    /// `ETH.0xa0b8…` for LI.FI and a bare `0xa0b8…` for Barter. Comparing our request string against
    /// whichever spelling an operator typed would catch one and silently miss the rest, so both
    /// sides normalize first (`CanonicalAssetId.of(token:)`) and compare the result.
    public let asset: String?
    public let chain: String?
    public let sellAsset: String?
    public let buyAsset: String?
    public let expiresAt: Date?

    public init(map: Map) throws {
        kind = Kind(rawValue: try map.value("kind")) ?? .asset
        side = Side(rawValue: (try? map.value("side")) ?? "any") ?? .any
        asset = try? map.value("asset")
        chain = try? map.value("chain")
        sellAsset = try? map.value("sellAsset")
        buyAsset = try? map.value("buyAsset")

        if let raw: String = try? map.value("expiresAt") {
            expiresAt = ISO8601DateFormatter().date(from: raw)
        } else {
            expiresAt = nil
        }
    }

    /// The server already filters expired rules out, but a cached list outlives its own contents —
    /// a rule that expires during the hour we hold the response must stop applying on its own.
    func isLive(at date: Date = Date()) -> Bool {
        guard let expiresAt else { return true }
        return expiresAt > date
    }

    func matches(sell: String?, buy: String?) -> Bool {
        switch kind {
        case .asset:
            return matchesSided(sell: sell, buy: buy) { $0 == asset }
        case .chain:
            return matchesSided(sell: sell, buy: buy) { CanonicalAssetId.chain(of: $0) == chain }
        case .pair:
            // Directed — the reverse direction is a separate rule.
            guard let sell, let buy else { return false }
            return sell == sellAsset && buy == buyAsset
        }
    }

    private func matchesSided(sell: String?, buy: String?, test: (String) -> Bool) -> Bool {
        if side != .buy, let sell, test(sell) { return true }
        if side != .sell, let buy, test(buy) { return true }
        return false
    }
}

/// Builds uswap-server's canonical asset ID for a local `Token`.
///
/// This is the client half of a two-implementation contract (the other is
/// `uswap-server/src/core/canonicalAsset.ts`). It is deliberately the SMALLER half: the server has
/// to parse every identifier spelling a client might send, whereas here the token is already
/// structured — a blockchain and a token type — so this only has to FORMAT, never parse. Keep it
/// that way; if this ever starts string-splitting identifiers, the two will drift.
enum CanonicalAssetId {
    /// Chain codes as uswap-server spells them (its `Chain` enum), which is what the ID is built
    /// from. A blockchain absent here yields no ID, so no rule can match it — the safe direction:
    /// a provider stays quotable rather than being silently suspended by a mapping gap.
    private static let chainCodes: [BlockchainType: String] = [
        .bitcoin: "BTC",
        .bitcoinCash: "BCH",
        .ecash: "XEC",
        .litecoin: "LTC",
        .dash: "DASH",
        .zcash: "ZEC",
        .monero: "XMR",
        .zano: "ZANO",
        .ethereum: "ETH",
        .binanceSmartChain: "BSC",
        .polygon: "POL",
        .avalanche: "AVAX",
        .optimism: "OP",
        .arbitrumOne: "ARB",
        .gnosis: "GNO",
        .base: "BASE",
        .tron: "TRON",
        .solana: "SOL",
        .ton: "TON",
        .stellar: "XLM",
        .thorChain: "THOR",
        .mayaChain: "MAYA",
    ]

    /// The gas asset's ticker per chain — NOT always the chain code (`BASE.ETH`, `BSC.BNB`,
    /// `GNO.XDAI`), which is exactly why this is a table and not a derivation.
    private static let nativeTickers: [BlockchainType: String] = [
        .bitcoin: "BTC",
        .bitcoinCash: "BCH",
        .ecash: "XEC",
        .litecoin: "LTC",
        .dash: "DASH",
        .zcash: "ZEC",
        .monero: "XMR",
        .zano: "ZANO",
        .ethereum: "ETH",
        .binanceSmartChain: "BNB",
        .polygon: "POL",
        .avalanche: "AVAX",
        .optimism: "ETH",
        .arbitrumOne: "ETH",
        .gnosis: "XDAI",
        .base: "ETH",
        .tron: "TRX",
        .solana: "SOL",
        .ton: "TON",
        .stellar: "XLM",
        .thorChain: "RUNE",
        .mayaChain: "CACAO",
    ]

    private static let wrappedSolMint = "So11111111111111111111111111111111111111112"

    static func of(token: Token) -> String? {
        guard let chain = chainCodes[token.blockchainType] else { return nil }

        switch token.type {
        case .native, .derived, .addressType:
            // Derivation / address type are wallet-side concerns; on the server they are all one
            // asset (`BTC.BTC`).
            guard let ticker = nativeTickers[token.blockchainType] else { return nil }
            return "\(chain).\(ticker)"

        case let .eip20(address):
            // Covers EVM hex and Tron base58 alike — both are upper-cased, matching the catalog
            // identifier's own convention (`ETH.USDC-0XA0B8…`).
            return "\(chain).\(address.uppercased())"

        case let .spl(address):
            // Wrapped SOL is native SOL everywhere on the server.
            guard address != wrappedSolMint else { return "\(chain).SOL" }
            return "\(chain).\(address.uppercased())"

        case let .jetton(address):
            return "\(chain).\(address.uppercased())"

        case let .stellar(code, issuer):
            // The CODE stays verbatim — Stellar codes are case-sensitive (`yXLM` ≠ `YXLM`). The
            // issuer is StrKey, uppercase-only, so normalizing it is safe.
            return "\(chain).\(code)-\(issuer.uppercased())"

        case let .thorChainAsset(denom):
            // THORChain secured (`eth-eth` in x/bank). Deliberately NOT chain-prefixed: the
            // canonical id is the identifier a quote itself uses, and `chainOfAsset` treats a
            // dot-less id as THORChain — which is where the asset actually lives.
            return denom.uppercased()

        case .zanoAsset, .unsupported:
            return nil
        }
    }

    /// The chain a canonical ID belongs to — what a chain-scoped rule matches on. A dot-less id can
    /// only be a THORChain secured asset (`ETH-ETH`), which lives in THORChain's x/bank — so a
    /// `THOR` chain rule covers it and an `ETH` one correctly does not.
    static func chain(of id: String) -> String {
        guard let separator = id.firstIndex(of: ".") else { return "THOR" }
        return String(id[id.startIndex ..< separator])
    }
}

/// The provider-id → rules index, plus the one question the swap screen asks.
public struct SwapSuspensionIndex {
    private let byProvider: [String: [SwapSuspension]]

    public init(byProvider: [String: [SwapSuspension]] = [:]) {
        self.byProvider = byProvider
    }

    /// May this provider be offered for this pair?
    ///
    /// A token we cannot normalize (an unmapped blockchain) yields `nil` and therefore never
    /// matches — deliberately failing OPEN. The alternative, treating "unknown" as suspended, would
    /// let one missing chain-code entry silently disable providers with no visible cause.
    public func isSuspended(providerId: String, tokenIn: Token, tokenOut: Token) -> Bool {
        guard let rules = byProvider[providerId], !rules.isEmpty else { return false }

        let sell = CanonicalAssetId.of(token: tokenIn)
        let buy = CanonicalAssetId.of(token: tokenOut)
        let now = Date()

        return rules.contains { $0.isLive(at: now) && $0.matches(sell: sell, buy: buy) }
    }
}

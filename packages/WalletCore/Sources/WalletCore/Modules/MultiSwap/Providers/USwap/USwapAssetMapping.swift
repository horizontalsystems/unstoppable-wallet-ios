import Foundation
import MarketKit
import ThorChainKit

/// Pure mapping between the app's tokens and uswap-server's asset vocabulary. Nothing here touches
/// `Core` or the network.
public enum USwapAssetMapping {
    /// `chainId` as the server spells it per blockchain. The inverse lookup (`chainId(blockchainType:)`)
    /// is what every `/rate`, `/preview` and `/split/*` request carries.
    public static let blockchainTypeMap: [String: BlockchainType] = [
        "bitcoin": .bitcoin,
        "bitcoincash": .bitcoinCash,
        "ecash": .ecash,
        "litecoin": .litecoin,
        "dash": .dash,
        "zcash": .zcash,
        "monero": .monero,
        "1": .ethereum,
        "56": .binanceSmartChain,
        "137": .polygon,
        "43114": .avalanche,
        "10": .optimism,
        "42161": .arbitrumOne,
        "100": .gnosis,
        "250": .fantom,
        "728126428": .tron,
        "solana": .solana,
        "ton": .ton,
        "8453": .base,
        "324": .zkSync,
        "4663": .robinhood,
        "5042": .arc,
        "stellar": .stellar,
        "ripple": .xrp,
        "near": .near,
        "zano": .zano,
        "thorchain-1": .thorChain,
        "mayachain-mainnet-v1": .mayaChain,
    ]

    /// The sentinel the server takes for an EVM native coin given as a bare address.
    static let evmNativeSentinel = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"

    public static func chainId(blockchainType: BlockchainType) -> String? {
        blockchainTypeMap.first(where: { $0.value == blockchainType })?.key
    }

    /// What a token the catalog does not list is sent as: the bare contract address / SPL mint, or the
    /// EVM native sentinel, together with the request's `chainId`. Only the venues that accept bare
    /// addresses (the same-chain DEX aggregators and Jupiter) answer such a request; every other family
    /// has no bare form and yields nil. No chain-prefixed string is ever built here.
    public static func bareAddress(token: Token) -> String? {
        switch token.type {
        case .native:
            return token.blockchainType.isEvm ? evmNativeSentinel : nil
        case let .eip20(address):
            // Tron contracts are `.eip20` too; the server takes them only chain-prefixed (LI.FI), so
            // only an EVM address has a bare form.
            return token.blockchainType.isEvm ? address : nil
        case let .spl(address):
            // base58 is case-sensitive: passed verbatim
            return token.blockchainType == .solana ? address : nil
        default:
            return nil
        }
    }

    /// The server's one-spelling-per-asset rule for comparing asset fields WITHIN a response (route
    /// `sellAsset` / `buyAsset`, track `fromAsset` / `toAsset`): drop a symbol between the chain and the
    /// contract, upper-case the rest. Never used to compare a request string with a response — the
    /// server may spell the asset differently from the request.
    public static func canonical(_ assetId: String) -> String {
        guard let dot = assetId.firstIndex(of: ".") else {
            return assetId.uppercased()
        }

        let chain = assetId[assetId.startIndex ..< dot].uppercased()
        let rest = assetId[assetId.index(after: dot)...]

        // `SYMBOL-CONTRACT` -> the contract alone; a Stellar `CODE-ISSUER` keeps its code (case-sensitive)
        if let dash = rest.firstIndex(of: "-") {
            let symbol = rest[rest.startIndex ..< dash]
            let contract = rest[rest.index(after: dash)...]

            if chain == "XLM" {
                return "\(chain).\(symbol)-\(contract.uppercased())"
            }

            return "\(chain).\(contract.uppercased())"
        }

        return "\(chain).\(rest.uppercased())"
    }

    /// Builds the catalog keyed by lower-cased token query id. A token the app knows under several
    /// queries (Litecoin derivations) gets one entry per query; two rows that resolve to the same query
    /// keep the one more providers list.
    public static func catalog(tokens: [USwapMultiSwapApi.CatalogToken]) -> [String: USwapCatalogEntry] {
        var catalog = [String: USwapCatalogEntry]()

        for token in tokens {
            guard let blockchainType = blockchainTypeMap[token.chainId] else {
                continue
            }

            let entry = USwapCatalogEntry(identifier: token.identifier, providerIds: token.providerIds)

            for tokenQuery in tokenQueries(
                blockchainType: blockchainType,
                identifier: token.identifier,
                address: token.address,
                ticker: token.ticker
            ) {
                let key = tokenQuery.id.lowercased()

                if let existing = catalog[key], existing != entry {
                    if existing.providerIds.count >= entry.providerIds.count {
                        print("[USwapAssetMapping] duplicate catalog row for \(key): kept \(existing.identifier), dropped \(entry.identifier)")
                        continue
                    }

                    print("[USwapAssetMapping] duplicate catalog row for \(key): kept \(entry.identifier), dropped \(existing.identifier)")
                }

                catalog[key] = entry
            }
        }

        return catalog
    }

    static func tokenQueries(blockchainType: BlockchainType, identifier: String, address: String?, ticker: String?) -> [TokenQuery] {
        switch blockchainType {
        case .ethereum, .binanceSmartChain, .polygon, .avalanche, .optimism, .arbitrumOne, .gnosis, .fantom, .tron, .base, .zkSync, .robinhood, .arc:
            let tokenType: TokenType

            if let address, !address.isEmpty {
                tokenType = .eip20(address: address)
            } else {
                tokenType = .native
            }

            return [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .ton:
            let tokenType: TokenType

            if let address, !address.isEmpty {
                tokenType = .jetton(address: address)
            } else {
                tokenType = .native
            }

            return [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .solana:
            let tokenType: TokenType

            if let address, !address.isEmpty {
                tokenType = .spl(address: address)
            } else {
                tokenType = .native
            }

            return [TokenQuery(blockchainType: blockchainType, tokenType: tokenType)]

        case .stellar:
            if let issuer = address, !issuer.isEmpty {
                guard let ticker else {
                    return []
                }

                return [
                    TokenQuery(
                        blockchainType: .stellar,
                        tokenType: .stellar(code: ticker, issuer: issuer)
                    ),
                ]
            }

            return blockchainType.nativeTokenQueries

        case .xrp:
            // Native XRP only: the server lists no XRPL issued currency, and a trust-line asset
            // has no canonical id (Android USwapProvider).
            guard address?.isEmpty ?? true else {
                return []
            }

            return blockchainType.nativeTokenQueries

        case .near:
            // `address` is the NEP-141 contract; native NEAR has none (the server routes it through
            // wrap.near itself, which is not the user's wNEAR token) - Android USwapProvider
            if let contractId = address, !contractId.isEmpty {
                return [TokenQuery(blockchainType: .near, tokenType: .nep141(contractId: contractId))]
            }

            return blockchainType.nativeTokenQueries

        case .bitcoin, .bitcoinCash, .ecash, .dash, .zcash, .monero:
            return blockchainType.nativeTokenQueries

        case .zano:
            if let assetId = address, !assetId.isEmpty {
                return [TokenQuery(blockchainType: .zano, tokenType: .zanoAsset(id: assetId))]
            } else {
                return blockchainType.nativeTokenQueries
            }

        case .litecoin:
            let supportedDerivations: [TokenType.Derivation] = [.bip44, .bip49, .bip84]
            return supportedDerivations.map {
                TokenQuery(blockchainType: .litecoin, tokenType: .derived(derivation: $0))
            }

        case .thorChain:
            // THORChain-chain entries carry no address: the identifier IS the asset notation
            // (THOR.RUNE, THOR.TCY, THOR.RUJI, or a secured asset such as BTC-BTC / ETH-USDC-0X…).
            // The bank denom follows ThorChainKit's rules: "rune" is the native coin, everything
            // else is a thorChainAsset token ("tcy", "x/ruji", "btc-btc", "eth-usdc-0xa0b8…").
            guard let asset = try? ThorChainKit.Asset(notation: identifier) else {
                return []
            }

            let denom = ThorChainKit.Denom.denom(for: asset)
            return [TokenQuery(blockchainType: .thorChain, tokenType: denom == "rune" ? .native : .thorChainAsset(denom: denom))]

        case .mayaChain:
            // Only the settlement coin is served (MAYA.CACAO); Maya lists no secured assets.
            guard let asset = try? ThorChainKit.Asset(notation: identifier), asset == .cacao else {
                return []
            }

            return blockchainType.nativeTokenQueries

        default:
            return []
        }
    }
}

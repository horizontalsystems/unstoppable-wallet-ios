public enum CoinType: Decodable {
    case bitcoin
    case bitcoinCash
    case litecoin
    case dash
    case zcash
    case ethereum
    case binanceSmartChain
    case polygon
    case ethereumOptimism
    case ethereumArbitrumOne
    case erc20(address: String)
    case bep20(address: String)
    case mrc20(address: String)
    case optimismErc20(address: String)
    case arbitrumOneErc20(address: String)
    case bep2(symbol: String)
    case avalanche(address: String)
    case fantom(address: String)
    case harmonyShard0(address: String)
    case huobiToken(address: String)
    case iotex(address: String)
    case moonriver(address: String)
    case okexChain(address: String)
    case solana(address: String)
    case sora(address: String)
    case tomochain(address: String)
    case xdai(address: String)
    case trc20(address: String)
    case unsupported(type: String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)

        self.init(id: value)
    }

    init?(type: String, address: String?, symbol: String?) {
        switch type {
        case "bitcoin": self = .bitcoin
        case "bitcoin-cash": self = .bitcoinCash
        case "litecoin": self = .litecoin
        case "dash": self = .dash
        case "zcash": self = .zcash
        case "ethereum": self = .ethereum
        case "binance-smart-chain": self = .binanceSmartChain
        case "polygon": self = .polygon
        case "ethereum-optimism": self = .ethereumOptimism
        case "ethereum-arbitrum-one": self = .ethereumArbitrumOne
        case "erc20": if let address { self = .erc20(address: address) } else { return nil }
        case "bep20": if let address { self = .bep20(address: address) } else { return nil }
        case "polygon-pos": if let address { self = .mrc20(address: address) } else { return nil }
        case "optimistic-ethereum": if let address { self = .optimismErc20(address: address) } else { return nil }
        case "arbitrum-one": if let address { self = .arbitrumOneErc20(address: address) } else { return nil }
        case "bep2": if let symbol { self = .bep2(symbol: symbol) } else { return nil }
        case "avalanche": if let address { self = .avalanche(address: address) } else { return nil }
        case "fantom": if let address { self = .fantom(address: address) } else { return nil }
        case "harmony-shard-0": if let address { self = .harmonyShard0(address: address) } else { return nil }
        case "huobi-token": if let address { self = .huobiToken(address: address) } else { return nil }
        case "iotex": if let address { self = .iotex(address: address) } else { return nil }
        case "moonriver": if let address { self = .moonriver(address: address) } else { return nil }
        case "okex-chain": if let address { self = .okexChain(address: address) } else { return nil }
        case "solana": if let address { self = .solana(address: address) } else { return nil }
        case "sora": if let address { self = .sora(address: address) } else { return nil }
        case "tomochain": if let address { self = .tomochain(address: address) } else { return nil }
        case "xdai": if let address { self = .xdai(address: address) } else { return nil }
        case "trc20": if let address { self = .trc20(address: address) } else { return nil }
        default: self = .unsupported(type: type)
        }
    }

    var coinTypeAttributes: (type: String, address: String?, symbol: String?) {
        switch self {
        case .bitcoin: return (type: "bitcoin", address: nil, symbol: nil)
        case .bitcoinCash: return (type: "bitcoin-cash", address: nil, symbol: nil)
        case .litecoin: return (type: "litecoin", address: nil, symbol: nil)
        case .dash: return (type: "dash", address: nil, symbol: nil)
        case .zcash: return (type: "zcash", address: nil, symbol: nil)
        case .ethereum: return (type: "ethereum", address: nil, symbol: nil)
        case .binanceSmartChain: return (type: "binance-smart-chain", address: nil, symbol: nil)
        case .polygon: return (type: "polygon", address: nil, symbol: nil)
        case .ethereumOptimism: return (type: "ethereum-optimism", address: nil, symbol: nil)
        case .ethereumArbitrumOne: return (type: "ethereum-arbitrum-one", address: nil, symbol: nil)
        case let .erc20(address): return (type: "erc20", address: address, symbol: nil)
        case let .bep20(address): return (type: "bep20", address: address, symbol: nil)
        case let .mrc20(address): return (type: "polygon-pos", address: address, symbol: nil)
        case let .optimismErc20(address): return (type: "optimistic-ethereum", address: address, symbol: nil)
        case let .arbitrumOneErc20(address): return (type: "arbitrum-one", address: address, symbol: nil)
        case let .bep2(symbol): return (type: "bep2", address: nil, symbol: symbol)
        case let .avalanche(address): return (type: "avalanche", address: address, symbol: nil)
        case let .fantom(address): return (type: "fantom", address: address, symbol: nil)
        case let .harmonyShard0(address): return (type: "harmony-shard-0", address: address, symbol: nil)
        case let .huobiToken(address): return (type: "huobi-token", address: address, symbol: nil)
        case let .iotex(address): return (type: "iotex", address: address, symbol: nil)
        case let .moonriver(address): return (type: "moonriver", address: address, symbol: nil)
        case let .okexChain(address): return (type: "okex-chain", address: address, symbol: nil)
        case let .solana(address): return (type: "solana", address: address, symbol: nil)
        case let .sora(address): return (type: "sora", address: address, symbol: nil)
        case let .tomochain(address): return (type: "tomochain", address: address, symbol: nil)
        case let .xdai(address): return (type: "xdai", address: address, symbol: nil)
        case let .trc20(address): return (type: "trc20", address: address, symbol: nil)
        case let .unsupported(type): return (type: type, address: nil, symbol: nil)
        }
    }
}

extension CoinType: Equatable {
    public static func == (lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.litecoin, .litecoin): return true
        case (.dash, .dash): return true
        case (.zcash, .zcash): return true
        case (.ethereum, .ethereum): return true
        case (.binanceSmartChain, .binanceSmartChain): return true
        case (.polygon, .polygon): return true
        case (.ethereumOptimism, .ethereumOptimism): return true
        case (.ethereumArbitrumOne, .ethereumArbitrumOne): return true
        case let (.erc20(lhsAddress), .erc20(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.bep20(lhsAddress), .bep20(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.mrc20(lhsAddress), .mrc20(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.optimismErc20(lhsAddress), .optimismErc20(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.arbitrumOneErc20(lhsAddress), .arbitrumOneErc20(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.bep2(lhsSymbol), .bep2(rhsSymbol)): return lhsSymbol == rhsSymbol
        case let (.avalanche(lhsAddress), .avalanche(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.fantom(lhsAddress), .fantom(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.harmonyShard0(lhsAddress), .harmonyShard0(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.huobiToken(lhsAddress), .huobiToken(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.iotex(lhsAddress), .iotex(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.moonriver(lhsAddress), .moonriver(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.okexChain(lhsAddress), .okexChain(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.solana(lhsAddress), .solana(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.sora(lhsAddress), .sora(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.tomochain(lhsAddress), .tomochain(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.xdai(lhsAddress), .xdai(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.trc20(lhsAddress), .trc20(rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case let (.unsupported(lhsType), .unsupported(rhsType)): return lhsType == rhsType
        default: return false
        }
    }
}

extension CoinType: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CoinType: Identifiable {
    public typealias ID = String

    public init(id: ID) {
        let chunks = id.split(separator: "|")

        if chunks.count == 1 {
            switch chunks[0] {
            case "bitcoin": self = .bitcoin
            case "bitcoinCash": self = .bitcoinCash
            case "litecoin": self = .litecoin
            case "dash": self = .dash
            case "zcash": self = .zcash
            case "ethereum": self = .ethereum
            case "binanceSmartChain": self = .binanceSmartChain
            case "polygon": self = .polygon
            case "ethereumOptimism": self = .ethereumOptimism
            case "ethereumArbitrumOne": self = .ethereumArbitrumOne
            default: self = .unsupported(type: String(chunks[0]))
            }
        } else {
            switch chunks[0] {
            case "erc20": self = .erc20(address: String(chunks[1]))
            case "bep20": self = .bep20(address: String(chunks[1]))
            case "mrc20": self = .mrc20(address: String(chunks[1]))
            case "optimismErc20": self = .optimismErc20(address: String(chunks[1]))
            case "arbitrumOneErc20": self = .arbitrumOneErc20(address: String(chunks[1]))
            case "bep2": self = .bep2(symbol: String(chunks[1]))
            case "avalanche": self = .avalanche(address: String(chunks[1]))
            case "fantom": self = .fantom(address: String(chunks[1]))
            case "harmonyShard0": self = .harmonyShard0(address: String(chunks[1]))
            case "huobiToken": self = .huobiToken(address: String(chunks[1]))
            case "iotex": self = .iotex(address: String(chunks[1]))
            case "moonriver": self = .moonriver(address: String(chunks[1]))
            case "okexChain": self = .okexChain(address: String(chunks[1]))
            case "solana": self = .solana(address: String(chunks[1]))
            case "sora": self = .sora(address: String(chunks[1]))
            case "tomochain": self = .tomochain(address: String(chunks[1]))
            case "xdai": self = .xdai(address: String(chunks[1]))
            case "trc20": self = .trc20(address: String(chunks[1]))
            case "unsupported": self = .unsupported(type: chunks.suffix(from: 1).joined(separator: "|"))
            default: self = .unsupported(type: chunks.joined(separator: "|"))
            }
        }
    }

    public var id: ID {
        switch self {
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoinCash"
        case .litecoin: return "litecoin"
        case .dash: return "dash"
        case .zcash: return "zcash"
        case .ethereum: return "ethereum"
        case .binanceSmartChain: return "binanceSmartChain"
        case .polygon: return "polygon"
        case .ethereumOptimism: return "ethereumOptimism"
        case .ethereumArbitrumOne: return "ethereumArbitrumOne"
        case let .erc20(address): return ["erc20", address].joined(separator: "|")
        case let .bep20(address): return ["bep20", address].joined(separator: "|")
        case let .mrc20(address): return ["mrc20", address].joined(separator: "|")
        case let .optimismErc20(address): return ["optimismErc20", address].joined(separator: "|")
        case let .arbitrumOneErc20(address): return ["arbitrumOneErc20", address].joined(separator: "|")
        case let .bep2(symbol): return ["bep2", symbol].joined(separator: "|")
        case let .avalanche(address): return ["avalanche", address].joined(separator: "|")
        case let .fantom(address): return ["fantom", address].joined(separator: "|")
        case let .harmonyShard0(address): return ["harmonyShard0", address].joined(separator: "|")
        case let .huobiToken(address): return ["huobiToken", address].joined(separator: "|")
        case let .iotex(address): return ["iotex", address].joined(separator: "|")
        case let .moonriver(address): return ["moonriver", address].joined(separator: "|")
        case let .okexChain(address): return ["okexChain", address].joined(separator: "|")
        case let .solana(address): return ["solana", address].joined(separator: "|")
        case let .sora(address): return ["sora", address].joined(separator: "|")
        case let .tomochain(address): return ["tomochain", address].joined(separator: "|")
        case let .xdai(address): return ["xdai", address].joined(separator: "|")
        case let .trc20(address): return ["trc20", address].joined(separator: "|")
        case let .unsupported(type): return ["unsupported", type].joined(separator: "|")
        }
    }
}

extension CoinType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .bitcoin: return "bitcoin"
        case .bitcoinCash: return "bitcoinCash"
        case .litecoin: return "litecoin"
        case .dash: return "dash"
        case .zcash: return "zcash"
        case .ethereum: return "ethereum"
        case .binanceSmartChain: return "binanceSmartChain"
        case .polygon: return "polygon"
        case .ethereumOptimism: return "ethereumOptimism"
        case .ethereumArbitrumOne: return "ethereumArbitrumOne"
        case let .erc20(address): return ["erc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .bep20(address): return ["bep20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .mrc20(address): return ["mrc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .optimismErc20(address): return ["optimismErc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .arbitrumOneErc20(address): return ["arbitrumOneErc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .bep2(symbol): return ["bep2", symbol].joined(separator: "|")
        case let .avalanche(address): return ["avalanche", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .fantom(address): return ["fantom", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .harmonyShard0(address): return ["harmonyShard0", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .huobiToken(address): return ["huobiToken", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .iotex(address): return ["iotex", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .moonriver(address): return ["moonriver", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .okexChain(address): return ["okexChain", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .solana(address): return ["solana", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .sora(address): return ["sora", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .tomochain(address): return ["tomochain", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .xdai(address): return ["xdai", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .trc20(address): return ["trc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case let .unsupported(type): return ["unsupported", type].joined(separator: "|")
        }
    }
}

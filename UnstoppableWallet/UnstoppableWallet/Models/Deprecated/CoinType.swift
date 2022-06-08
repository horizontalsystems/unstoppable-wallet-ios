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
        case "erc20": if let address = address { self = .erc20(address: address) } else { return nil }
        case "bep20": if let address = address { self = .bep20(address: address) } else { return nil }
        case "polygon-pos": if let address = address { self = .mrc20(address: address) } else { return nil }
        case "optimistic-ethereum": if let address = address { self = .optimismErc20(address: address) } else { return nil }
        case "arbitrum-one": if let address = address { self = .arbitrumOneErc20(address: address) } else { return nil }
        case "bep2": if let symbol = symbol { self = .bep2(symbol: symbol) } else { return nil }
        case "avalanche": if let address = address { self = .avalanche(address: address) } else { return nil }
        case "fantom": if let address = address { self = .fantom(address: address) } else { return nil }
        case "harmony-shard-0": if let address = address { self = .harmonyShard0(address: address) } else { return nil }
        case "huobi-token": if let address = address { self = .huobiToken(address: address) } else { return nil }
        case "iotex": if let address = address { self = .iotex(address: address) } else { return nil }
        case "moonriver": if let address = address { self = .moonriver(address: address) } else { return nil }
        case "okex-chain": if let address = address { self = .okexChain(address: address) } else { return nil }
        case "solana": if let address = address { self = .solana(address: address) } else { return nil }
        case "sora": if let address = address { self = .sora(address: address) } else { return nil }
        case "tomochain": if let address = address { self = .tomochain(address: address) } else { return nil }
        case "xdai": if let address = address { self = .xdai(address: address) } else { return nil }
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
        case .erc20(let address): return (type: "erc20", address: address, symbol: nil)
        case .bep20(let address): return (type: "bep20", address: address, symbol: nil)
        case .mrc20(let address): return (type: "polygon-pos", address: address, symbol: nil)
        case .optimismErc20(let address): return (type: "optimistic-ethereum", address: address, symbol: nil)
        case .arbitrumOneErc20(let address): return (type: "arbitrum-one", address: address, symbol: nil)
        case .bep2(let symbol): return (type: "bep2", address: nil, symbol: symbol)
        case .avalanche(let address): return (type: "avalanche", address: address, symbol: nil)
        case .fantom(let address): return (type: "fantom", address: address, symbol: nil)
        case .harmonyShard0(let address): return (type: "harmony-shard-0", address: address, symbol: nil)
        case .huobiToken(let address): return (type: "huobi-token", address: address, symbol: nil)
        case .iotex(let address): return (type: "iotex", address: address, symbol: nil)
        case .moonriver(let address): return (type: "moonriver", address: address, symbol: nil)
        case .okexChain(let address): return (type: "okex-chain", address: address, symbol: nil)
        case .solana(let address): return (type: "solana", address: address, symbol: nil)
        case .sora(let address): return (type: "sora", address: address, symbol: nil)
        case .tomochain(let address): return (type: "tomochain", address: address, symbol: nil)
        case .xdai(let address): return (type: "xdai", address: address, symbol: nil)
        case .unsupported(let type): return (type: type, address: nil, symbol: nil)
        }
    }

}

extension CoinType: Equatable {

    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
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
        case (.erc20(let lhsAddress), .erc20(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.bep20(let lhsAddress), .bep20(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.mrc20(let lhsAddress), .mrc20(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.optimismErc20(let lhsAddress), .optimismErc20(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.arbitrumOneErc20(let lhsAddress), .arbitrumOneErc20(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.bep2(let lhsSymbol), .bep2(let rhsSymbol)): return lhsSymbol == rhsSymbol
        case (.avalanche(let lhsAddress), .avalanche(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.fantom(let lhsAddress), .fantom(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.harmonyShard0(let lhsAddress), .harmonyShard0(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.huobiToken(let lhsAddress), .huobiToken(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.iotex(let lhsAddress), .iotex(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.moonriver(let lhsAddress), .moonriver(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.okexChain(let lhsAddress), .okexChain(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.solana(let lhsAddress), .solana(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.sora(let lhsAddress), .sora(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.tomochain(let lhsAddress), .tomochain(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.xdai(let lhsAddress), .xdai(let rhsAddress)): return lhsAddress.lowercased() == rhsAddress.lowercased()
        case (.unsupported(let lhsType), .unsupported(let rhsType)): return lhsType == rhsType
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
        case .erc20(let address): return ["erc20", address].joined(separator: "|")
        case .bep20(let address): return ["bep20", address].joined(separator: "|")
        case .mrc20(let address): return ["mrc20", address].joined(separator: "|")
        case .optimismErc20(let address): return ["optimismErc20", address].joined(separator: "|")
        case .arbitrumOneErc20(let address): return ["arbitrumOneErc20", address].joined(separator: "|")
        case .bep2(let symbol): return ["bep2", symbol].joined(separator: "|")
        case .avalanche(let address): return ["avalanche", address].joined(separator: "|")
        case .fantom(let address): return ["fantom", address].joined(separator: "|")
        case .harmonyShard0(let address): return ["harmonyShard0", address].joined(separator: "|")
        case .huobiToken(let address): return ["huobiToken", address].joined(separator: "|")
        case .iotex(let address): return ["iotex", address].joined(separator: "|")
        case .moonriver(let address): return ["moonriver", address].joined(separator: "|")
        case .okexChain(let address): return ["okexChain", address].joined(separator: "|")
        case .solana(let address): return ["solana", address].joined(separator: "|")
        case .sora(let address): return ["sora", address].joined(separator: "|")
        case .tomochain(let address): return ["tomochain", address].joined(separator: "|")
        case .xdai(let address): return ["xdai", address].joined(separator: "|")
        case .unsupported(let type): return ["unsupported", type].joined(separator: "|")
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
        case .erc20(let address): return ["erc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .bep20(let address): return ["bep20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .mrc20(let address): return ["mrc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .optimismErc20(let address): return ["optimismErc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .arbitrumOneErc20(let address): return ["arbitrumOneErc20", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .bep2(let symbol): return ["bep2", symbol].joined(separator: "|")
        case .avalanche(let address): return ["avalanche", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .fantom(let address): return ["fantom", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .harmonyShard0(let address): return ["harmonyShard0", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .huobiToken(let address): return ["huobiToken", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .iotex(let address): return ["iotex", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .moonriver(let address): return ["moonriver", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .okexChain(let address): return ["okexChain", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .solana(let address): return ["solana", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .sora(let address): return ["sora", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .tomochain(let address): return ["tomochain", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .xdai(let address): return ["xdai", "\(address.prefix(4))...\(address.suffix(2))"].joined(separator: "|")
        case .unsupported(let type): return ["unsupported", type].joined(separator: "|")
        }
    }

}

import Foundation

enum CoinType {
    case bitcoin
    case litecoin
    case bitcoinCash
    case dash
    case ethereum
    case erc20(address: String, fee: Decimal, minimumRequiredBalance: Decimal, minimumSpendableAmount: Decimal?)
    case binance(symbol: String)
    case zcash

    init(erc20Address: String, fee: Decimal = 0, minimumRequiredBalance: Decimal = 0, minimumSpendableAmount: Decimal? = nil) {
        self = .erc20(address: erc20Address, fee: fee, minimumRequiredBalance: minimumRequiredBalance, minimumSpendableAmount: minimumSpendableAmount)
    }

    func canSupport(accountType: AccountType) -> Bool {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .dash, .ethereum, .erc20:
            if case let .mnemonic(words, salt) = accountType, words.count == 12, salt == nil { return true }
            return false
        case .binance:
            if case let .mnemonic(words, salt) = accountType, words.count == 24, salt == nil { return true }
            return false
        case .zcash:
            if case .zcash = accountType { return true }
            return false
        }
    }

    var predefinedAccountType: PredefinedAccountType {
        switch self {
        case .bitcoin, .litecoin, .bitcoinCash, .dash, .ethereum, .erc20:
            return .standard
        case .binance:
            return .binance
        case .zcash:
            return .zcash
        }
    }

    var blockchainType: String? {
        switch self {
        case .erc20: return "ERC20"
        case .binance(let symbol):
            if symbol != "BNB" {
                return "BEP2"
            }
        default: ()
        }

        return nil
    }

    var swappable: Bool {
        switch self {
        case .ethereum, .erc20: return true
        default: return false
        }
    }

    var restoreUrl: String {
        switch self {
        case .bitcoin: return "https://btc.horizontalsystems.xyz/apg"
        case .litecoin: return "https://ltc.horizontalsystems.xyz/api"
        case .bitcoinCash: return "https://explorer.bitcoin.com/bch/"
        case .dash: return "https://dash.horizontalsystems.xyz"
        default: return ""
        }
    }

    var title: String {
        switch self {
        case .bitcoin: return "Bitcoin"
        case .litecoin: return "Litecoin"
        case .bitcoinCash: return "Bitcoin Cash"
        default: return ""
        }
    }

}

extension CoinType: Equatable {

    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.litecoin, .litecoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.dash, .dash): return true
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsAddress, let lhsFee, _, _), .erc20(let rhsAddress, let rhsFee, _, _)):
            return lhsAddress == rhsAddress && lhsFee == rhsFee
        case (.binance(let lhsSymbol), .binance(let rhsSymbol)):
            return lhsSymbol == rhsSymbol
        case (.zcash, .zcash): return true
        default: return false
        }
    }

}

extension CoinType: Hashable {

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .bitcoin:
            hasher.combine("bitcoin")
        case .litecoin:
            hasher.combine("litecoin")
        case .bitcoinCash:
            hasher.combine("bitcoinCash")
        case .dash:
            hasher.combine("dash")
        case .ethereum:
            hasher.combine("ethereum")
        case .erc20(let address, let fee, let minimumRequiredBalance, let minimumSpendableAmount):
            hasher.combine("erc20_\(address)_\(fee)_\(minimumRequiredBalance)_\(minimumSpendableAmount.map { "\($0)" } ?? "nil")")
        case .binance(let symbol):
            hasher.combine("binance_\(symbol)")
        case .zcash:
            hasher.combine("Zcash")
        }
    }

}

extension CoinType: RawRepresentable {
    public typealias RawValue = String

    public init?(rawValue: RawValue) {
        if rawValue.hasPrefix("erc20"), let address = rawValue.split(separator: "|").last {
            self = .erc20(address: String(address), fee: 0, minimumRequiredBalance: 0, minimumSpendableAmount: nil)
            return
        }

        if rawValue.hasPrefix("binance"), let symbol = rawValue.split(separator: "|").last {
            self = .binance(symbol: String(symbol))
        }

        var type: Self?

        switch rawValue {
        case "bitcoin": type = .bitcoin
        case "litecoin": type = .litecoin
        case "bitcoinCash": type = .bitcoinCash
        case "dash": type = .dash
        case "ethereum": type = .ethereum
        case "zcash": type = .zcash
        default: type = nil
        }

        guard let coinType = type else {
            return nil
        }

        self = coinType
    }

    public var rawValue: RawValue {
        switch self {
        case .bitcoin: return "bitcoin"
        case .litecoin: return "litecoin"
        case .bitcoinCash: return "bitcoinCash"
        case .dash: return "dash"
        case .ethereum: return "ethereum"
        case .erc20(let address, _, _, _): return "erc20|\(address)"
        case .binance(let symbol): return "binance|\(symbol)"
        case .zcash: return "zcash"
        }
    }

}

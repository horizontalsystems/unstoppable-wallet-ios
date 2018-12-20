enum CoinType {
    case bitcoin
    case bitcoinCash
    case ethereum
    case erc20(address: String, decimal: Int)
}

struct Coin {
    let title: String
    let code: CoinCode
    let type: CoinType
}

extension Coin: Equatable {
    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        let codes = lhs.code == rhs.code
        let titles = lhs.title == rhs.title
        return codes && titles && lhs.type == rhs.type
    }
}

extension CoinType: Equatable {
    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsAddress, let lhsDecimal), .erc20(let rhsAddress, let rhsDecimal)):
            return lhsAddress == rhsAddress && lhsDecimal == rhsDecimal
        default: return false
        }
    }
}

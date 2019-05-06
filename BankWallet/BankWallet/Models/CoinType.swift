import Foundation

enum CoinType {
    case bitcoin
    case bitcoinCash
    case dash
    case ethereum
    case erc20(address: String, decimal: Int, fee: Decimal)
}

extension CoinType: Equatable {

    public static func ==(lhs: CoinType, rhs: CoinType) -> Bool {
        switch (lhs, rhs) {
        case (.bitcoin, .bitcoin): return true
        case (.bitcoinCash, .bitcoinCash): return true
        case (.dash, .dash): return true
        case (.ethereum, .ethereum): return true
        case (.erc20(let lhsAddress, let lhsDecimal, let lhsFee), .erc20(let rhsAddress, let rhsDecimal, let rhsFee)):
            return lhsAddress == rhsAddress && lhsDecimal == rhsDecimal && lhsFee == rhsFee
        default: return false
        }
    }

}

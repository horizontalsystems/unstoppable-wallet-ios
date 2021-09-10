import Foundation
import MarketKit
import BigInt

enum TransactionValue {
    case coinValue(platformCoin: PlatformCoin, value: Decimal)
    case rawValue(coinType: CoinType, value: BigUInt)

    var coinName: String {
        coin?.name ?? ""
    }

    var coinCode: String {
        coin?.code ?? ""
    }

    var coin: Coin? {
        switch self {
        case .coinValue(let platformCoin, _): return platformCoin.coin
        case .rawValue: return nil
        }
    }

    var decimalValue: Decimal? {
        switch self {
        case .coinValue(_, let value): return value
        case .rawValue: return nil
        }
    }

    var zeroValue: Bool {
        switch self {
        case .coinValue(_, let value): return value == 0
        case .rawValue(_, let value): return value == 0
        }
    }

    public var isMaxValue: Bool {
        switch self {
        case .coinValue(let platformCoin, let value): return CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: value).isMaxValue
        case .rawValue(_, let value): return false
        }
    }

    var abs: TransactionValue {
        switch self {
        case .coinValue(let platformCoin, let value): return .coinValue(platformCoin: platformCoin, value: value.magnitude)
        case .rawValue(let coinType, let value): return .rawValue(coinType: coinType, value: value)
        }
    }

    var formattedString: String {
        switch self {
        case .coinValue(let platformCoin, let value):
            let coinValue = CoinValueNew(kind: .platformCoin(platformCoin: platformCoin), value: value)

            return ValueFormatter.instance.format(transactionValue: self) ?? ""

        case .rawValue: return "n/a"
        }
    }

}

extension TransactionValue: Equatable {

    static func ==(lhs: TransactionValue, rhs: TransactionValue) -> Bool {
        switch (lhs, rhs) {
        case (.coinValue(let lhsPlatformCoin, let lhsValue), .coinValue(let rhsPlatformCoin, let rhsValue)): return lhsPlatformCoin == rhsPlatformCoin && lhsValue == rhsValue
        case (.rawValue(let lhsCoinType, let lhsValue), .rawValue(let rhsCoinType, let rhsValue)): return lhsCoinType == rhsCoinType && lhsValue == rhsValue
        default: return false
        }
    }

}

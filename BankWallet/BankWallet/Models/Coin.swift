import GRDB

enum CoinType {
    static let bitcoinKey = "bitcoin_key"
    static let bitcoinCashKey = "bitcoin_cash_key"
    static let ethereumKey = "ethereum_key"
    static let erc20Key = "erc_20_key"

    case bitcoin
    case bitcoinCash
    case ethereum
    case erc20(address: String, decimal: Int)
}

extension CoinType: DatabaseValueConvertible {

    public var databaseValue: DatabaseValue {
        switch self {
        case .bitcoin: return CoinType.bitcoinKey.databaseValue
        case .bitcoinCash: return CoinType.bitcoinCashKey.databaseValue
        case .ethereum: return CoinType.ethereumKey.databaseValue
        case .erc20(let address, let decimal): return "\(CoinType.erc20Key);\(address);\(decimal)".databaseValue
        }
    }

    public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> CoinType? {
        guard case .string(let rawValue) = dbValue.storage else {
            return nil
        }

        switch rawValue {
        case CoinType.bitcoinKey: return .bitcoin
        case CoinType.bitcoinCashKey: return .bitcoinCash
        case CoinType.ethereumKey: return .ethereum
        case let value where rawValue.contains(CoinType.erc20Key):
            let values = value.split(separator:";")
            guard values.count == 3, let decimal = Int(values[2]) else {
                return nil
            }
            return .erc20(address: String(values[1]), decimal: decimal)
        default: return nil
        }
    }

}

struct Coin {
    let title: String
    let code: CoinCode
    let type: CoinType
}

class StorableCoin: Record {
    var coin: Coin
    var enabled: Bool
    var order: Int?

    init(coin: Coin, enabled: Bool, order: Int?) {
        self.coin = coin
        self.enabled = enabled
        self.order = order
        super.init()
    }

    enum Columns: String, ColumnExpression {
        case title, code, enabled, type, coinOrder
    }

    required init(row: Row) {
        let title: String = row[Columns.title]
        let code: String = row[Columns.code]
        let type: CoinType = row[Columns.type]

        enabled = row[Columns.enabled]
        order = row[Columns.coinOrder]

        coin = Coin(title: title, code: code, type: type)

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.title] = coin.title
        container[Columns.code] = coin.code
        container[Columns.type] = coin.type

        container[Columns.enabled] = enabled
        container[Columns.coinOrder] = order
    }

    override class var databaseTableName: String {
        return "coins"
    }

}

extension Coin: Equatable {
    public static func ==(lhs: Coin, rhs: Coin) -> Bool {
        return lhs.code == rhs.code && lhs.title == rhs.title && lhs.type == rhs.type
    }
}

extension Coin: Comparable {
    public static func <(lhs: Coin, rhs: Coin) -> Bool {
        return lhs.title < rhs.title
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

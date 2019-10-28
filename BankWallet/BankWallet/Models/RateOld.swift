import GRDB

class RateOld: Record {
    static let latestRateFallbackThreshold: Double = 60 * 10 // in seconds
    
    let coinCode: String
    let currencyCode: String
    let value: Decimal
    let date: Date
    let isLatest: Bool

    init(coinCode: String, currencyCode: String, value: Decimal, date: Date, isLatest: Bool) {
        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.value = value
        self.date = date
        self.isLatest = isLatest

        super.init()
    }

    var expired: Bool {
        let diff = Date().timeIntervalSince1970 - date.timeIntervalSince1970
        return diff > RateOld.latestRateFallbackThreshold
    }

    override class var databaseTableName: String {
        return "rate"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, value, date, isLatest
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        currencyCode = row[Columns.currencyCode]
        value = row[Columns.value]
        date = row[Columns.date]
        isLatest = row[Columns.isLatest]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = currencyCode
        container[Columns.value] = value
        container[Columns.date] = date
        container[Columns.isLatest] = isLatest
    }

}

extension RateOld: CustomStringConvertible {

    public var description: String {
        return "Rate [coinCode: \(coinCode); currencyCode: \(currencyCode); value: \(value); date: \(DateHelper.instance.formatDebug(date: date)); isLatest: \(isLatest)]"
    }

}

extension RateOld: Equatable {
    public static func ==(lhs: RateOld, rhs: RateOld) -> Bool {
        return lhs.value == rhs.value && lhs.coinCode == rhs.coinCode && lhs.currencyCode == rhs.currencyCode && lhs.date == rhs.date && lhs.isLatest == rhs.isLatest
    }
}

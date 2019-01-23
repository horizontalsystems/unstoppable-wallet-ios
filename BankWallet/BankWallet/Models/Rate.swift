import GRDB

class Rate: Record {
    let coinCode: String
    let currencyCode: String
    let value: Double
    let timestamp: Double
    let isLatest: Bool

    init(coinCode: String, currencyCode: String, value: Double, timestamp: Double, isLatest: Bool) {
        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.value = value
        self.timestamp = timestamp
        self.isLatest = isLatest

        super.init()
    }

    var expired: Bool {
        let diff = Date().timeIntervalSince1970 - timestamp
        return diff > 60 * 10
    }

    override class var databaseTableName: String {
        return "rate"
    }

    enum Columns: String, ColumnExpression {
        case coinCode, currencyCode, value, timestamp, isLatest
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        currencyCode = row[Columns.currencyCode]
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]
        isLatest = row[Columns.isLatest]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = currencyCode
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
        container[Columns.isLatest] = isLatest
    }

}

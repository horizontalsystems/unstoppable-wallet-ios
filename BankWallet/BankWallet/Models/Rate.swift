import GRDB

class Rate: Record {
    let coinCode: String
    let currencyCode: String
    let value: Double
    let timestamp: Double

    init(coinCode: String, currencyCode: String, value: Double, timestamp: Double) {
        self.coinCode = coinCode
        self.currencyCode = currencyCode
        self.value = value
        self.timestamp = timestamp

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
        case coinCode, currencyCode, value, timestamp
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        currencyCode = row[Columns.currencyCode]
        value = row[Columns.value]
        timestamp = row[Columns.timestamp]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.currencyCode] = currencyCode
        container[Columns.value] = value
        container[Columns.timestamp] = timestamp
    }

}

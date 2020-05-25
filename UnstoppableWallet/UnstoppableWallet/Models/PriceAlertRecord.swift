import GRDB

class PriceAlertRecord: Record {
    let coinCode: CoinCode
    let state: AlertState
    let lastRate: Decimal?

    init(coinCode: CoinCode, state: AlertState, lastRate: Decimal?) {
        self.coinCode = coinCode
        self.state = state
        self.lastRate = lastRate

        super.init()
    }

    override class var databaseTableName: String {
        "price_alert_records"
    }

    enum Columns: String, ColumnExpression {
        case coinCode
        case state
        case lastRate
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        state = row[Columns.state].flatMap { AlertState(rawValue: $0) } ?? .off
        lastRate = row[Columns.lastRate]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.state] = state.rawValue
        container[Columns.lastRate] = lastRate
    }

}

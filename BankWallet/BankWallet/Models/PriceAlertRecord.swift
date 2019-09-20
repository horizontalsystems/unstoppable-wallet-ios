import GRDB

class PriceAlertRecord: Record {
    let coinCode: CoinCode
    let state: AlertState

    init(coinCode: CoinCode, state: AlertState) {
        self.coinCode = coinCode
        self.state = state

        super.init()
    }

    override class var databaseTableName: String {
        return "price_alert_records"
    }

    enum Columns: String, ColumnExpression {
        case coinCode
        case state
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        state = row[Columns.state].flatMap { AlertState(rawValue: $0) } ?? .off

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.state] = state.rawValue
    }

}

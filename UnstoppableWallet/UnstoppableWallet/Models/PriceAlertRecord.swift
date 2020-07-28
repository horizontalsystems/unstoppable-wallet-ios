import GRDB

class PriceAlertRecord: Record {
    let coinCode: CoinCode
    let changeState: PriceAlert.ChangeState
    let trendState: PriceAlert.TrendState

    init(coinCode: CoinCode, changeState: PriceAlert.ChangeState, trendState: PriceAlert.TrendState) {
        self.coinCode = coinCode
        self.changeState = changeState
        self.trendState = trendState

        super.init()
    }

    override class var databaseTableName: String {
        "price_alert_records"
    }

    enum Columns: String, ColumnExpression {
        case coinCode
        case changeState
        case trendState
    }

    required init(row: Row) {
        coinCode = row[Columns.coinCode]
        changeState = row[Columns.changeState].flatMap { PriceAlert.ChangeState(rawValue: $0) } ?? .off
        trendState = row[Columns.trendState].flatMap { PriceAlert.TrendState(rawValue: $0) } ?? .off

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinCode] = coinCode
        container[Columns.changeState] = changeState.rawValue
        container[Columns.trendState] = trendState.rawValue
    }

}

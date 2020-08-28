import GRDB

class PriceAlertRecord: Record {
    let coinId: String
    let changeState: PriceAlert.ChangeState
    let trendState: PriceAlert.TrendState

    init(coinId: String, changeState: PriceAlert.ChangeState, trendState: PriceAlert.TrendState) {
        self.coinId = coinId
        self.changeState = changeState
        self.trendState = trendState

        super.init()
    }

    override class var databaseTableName: String {
        "price_alert_records"
    }

    enum Columns: String, ColumnExpression {
        case coinId
        case changeState
        case trendState
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        changeState = row[Columns.changeState].flatMap { PriceAlert.ChangeState(rawValue: $0) } ?? .off
        trendState = row[Columns.trendState].flatMap { PriceAlert.TrendState(rawValue: $0) } ?? .off

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.changeState] = changeState.rawValue
        container[Columns.trendState] = trendState.rawValue
    }

}

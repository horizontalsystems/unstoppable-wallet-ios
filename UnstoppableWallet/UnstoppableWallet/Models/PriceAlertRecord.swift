import GRDB

class PriceAlertRecord: Record {
    let coinId: String
    let coinTitle: String
    let changeState: PriceAlert.ChangeState
    let trendState: PriceAlert.TrendState

    init(coinId: String, coinTitle: String, changeState: PriceAlert.ChangeState, trendState: PriceAlert.TrendState) {
        self.coinId = coinId
        self.coinTitle = coinTitle
        self.changeState = changeState
        self.trendState = trendState

        super.init()
    }

    override class var databaseTableName: String {
        "price_alert_records"
    }

    enum Columns: String, ColumnExpression {
        case coinId
        case coinTitle
        case changeState
        case trendState
    }

    required init(row: Row) {
        coinId = row[Columns.coinId]
        coinTitle = row[Columns.coinTitle]
        changeState = row[Columns.changeState].flatMap { PriceAlert.ChangeState(rawValue: $0) } ?? .off
        trendState = row[Columns.trendState].flatMap { PriceAlert.TrendState(rawValue: $0) } ?? .off

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.coinId] = coinId
        container[Columns.coinTitle] = coinTitle
        container[Columns.changeState] = changeState.rawValue
        container[Columns.trendState] = trendState.rawValue
    }

}

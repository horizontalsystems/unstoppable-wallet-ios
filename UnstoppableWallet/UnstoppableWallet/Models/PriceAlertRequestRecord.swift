import GRDB

class PriceAlertRequestRecord: Record {
    let topic: String
    let method: PriceAlertRequest.Method

    init(topic: String, method: PriceAlertRequest.Method) {
        self.topic = topic
        self.method = method

        super.init()
    }

    override class var databaseTableName: String {
        "price_alert_requests_records"
    }

    enum Columns: String, ColumnExpression {
        case topic
        case method
    }

    required init(row: Row) {
        topic = row[Columns.topic]
        method = row[Columns.method].flatMap { PriceAlertRequest.Method(rawValue: $0) } ?? .unsubscribe

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.topic] = topic
        container[Columns.method] = method.rawValue
    }

}

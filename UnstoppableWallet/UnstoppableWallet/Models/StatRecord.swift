import Foundation
import GRDB

class StatRecord: Record {
    let eventPage: String
    let eventSection: String?
    let event: String
    let params: [String: Any]?

    init(eventPage: String, eventSection: String?, event: String, params: [String: Any]?) {
        self.eventPage = eventPage
        self.eventSection = eventSection
        self.event = event
        self.params = params

        super.init()
    }

    override class var databaseTableName: String {
        "StatRecord"
    }

    enum Columns: String, ColumnExpression {
        case eventPage, eventSection, event, params
    }

    required init(row: Row) throws {
        eventPage = row[Columns.eventPage]
        eventSection = row[Columns.eventSection]
        event = row[Columns.event]
        let paramsData: Data? = row[Columns.params]

        if let paramsData, let jsonObject = try? JSONSerialization.jsonObject(with: paramsData), let params = jsonObject as? [String: Any] {
            self.params = params
        } else {
            params = nil
        }

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.eventPage] = eventPage
        container[Columns.eventSection] = eventSection
        container[Columns.event] = event
        container[Columns.params] = params.flatMap { try? JSONSerialization.data(withJSONObject: $0) }
    }
}

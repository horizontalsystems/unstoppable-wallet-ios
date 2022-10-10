import Foundation
import GRDB

class AppVersionRecord: Record {
    var version: String
    var build: String?
    var date: Date

    init(version: String, build: String?, date: Date) {
        self.version = version
        self.build = build
        self.date = date

        super.init()
    }

    override class var databaseTableName: String {
        "app_version_records"
    }

    enum Columns: String, ColumnExpression {
        case version
        case build
        case date
    }

    required init(row: Row) {
        version = row[Columns.version]
        build = row[Columns.build]
        date = row[Columns.date]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.version] = version
        container[Columns.build] = build
        container[Columns.date] = date
    }

}

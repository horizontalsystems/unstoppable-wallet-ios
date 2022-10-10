import Foundation
import GRDB
import HsToolKit

class LogRecord: Record {
    let date: TimeInterval
    let level: Int
    let context: String
    let message: String

    var levelString: String {
        guard let level = Logger.Level(rawValue: level) else {
            return ""
        }

        switch level {
        case .verbose: return "verbose"
        case .info: return "info"
        case .debug: return "debug"
        case .warning: return "warning"
        case .error: return "error"
        }
    }

    init(date: TimeInterval, level: Logger.Level, context: String, message: String) {
        self.date = date
        self.level = level.rawValue
        self.context = context
        self.message = message

        super.init()
    }

    override class var databaseTableName: String {
        "logs"
    }

    enum Columns: String, ColumnExpression {
        case date, level, context, message
    }

    required init(row: Row) {
        date = row[Columns.date]
        level = row[Columns.level]
        message = row[Columns.message]
        context = row[Columns.context]

        super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) {
        container[Columns.date] = date
        container[Columns.level] = level
        container[Columns.context] = context
        container[Columns.message] = message
    }

}

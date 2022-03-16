import GRDB

class LogRecordStorage {
    private let dbPool: DatabasePool

    init(dbPool: DatabasePool) {
        self.dbPool = dbPool
    }

}

extension LogRecordStorage {

    func logs(context: String) -> [LogRecord] {
        try! dbPool.read { db in
            try LogRecord
                    .filter(LogRecord.Columns.context.like("\(context)%"))
                    .order(LogRecord.Columns.date.asc)
                    .fetchAll(db)
        }
    }

    func save(logRecord: LogRecord) {
        _ = try? dbPool.write { db in
            try logRecord.insert(db)
        }
    }

    func logsCount() -> Int {
        try! dbPool.read { db in
            try LogRecord.fetchCount(db)
        }
    }

    func removeFirstLogs(count: Int) {
        _ = try! dbPool.write { db in
            let logs = try LogRecord.order(LogRecord.Columns.date.asc).limit(count).fetchAll(db)
            if let last = logs.last {
                try LogRecord.filter(LogRecord.Columns.date <= last.date).deleteAll(db)
            }
        }
    }

}

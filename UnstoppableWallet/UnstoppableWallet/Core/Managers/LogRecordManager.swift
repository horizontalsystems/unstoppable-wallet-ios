import Foundation
import HsToolKit

class LogRecordManager {
    private let linesCountLimit: Int
    private let storage: LogRecordStorage

    init(storage: LogRecordStorage, linesCountLimit: Int = 1000) {
        self.storage = storage
        self.linesCountLimit = linesCountLimit
    }

    func logsGroupedBy(context: String) -> [(String, Any)] {
        let logs = storage.logs(context: context)

        return Dictionary(grouping: logs, by: { $0.context })
                        .sorted { (a: (String, [LogRecord]), b: (String, [LogRecord])) in
                            guard let aFirst = a.1.first, let bFirst = b.1.first else {
                                return true
                            }

                            return aFirst.date < bFirst.date
                        }
                        .map { (key: String, logs: [LogRecord]) -> (String, Any) in
                            (key, logs.map { log in
                                "\(Date(timeIntervalSince1970: log.date)) [\(log.levelString)]: \(log.message)"
                            })
                        }
    }

    func onBecomeActive() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let manager = self else {
                return
            }

            let logsCount = manager.storage.logsCount()
            if logsCount > manager.linesCountLimit {
                manager.storage.removeFirstLogs(count: logsCount - manager.linesCountLimit)
            }
        }
    }

}

extension LogRecordManager: ILogStorage {

    func log(date: Date, level: Logger.Level, message: String, file: String?, function: String?, line: Int?, context: [String]?) {
        let context = context?.joined(separator: ":") ?? ""
        let record = LogRecord(date: date.timeIntervalSince1970, level: level, context: context, message: message)

        storage.save(logRecord: record)
    }

}

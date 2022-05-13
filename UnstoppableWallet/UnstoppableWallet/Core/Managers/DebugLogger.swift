import Foundation

class DebugLogger {
    private let localStorage: LocalStorage
    private let dateProvider: CurrentDateProvider

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.debug_logger", qos: .background)

    init(localStorage: LocalStorage, dateProvider: CurrentDateProvider) {
        self.localStorage = localStorage
        self.dateProvider = dateProvider
    }

    private func updateLogs(with log: String) {
        queue.async {
            var fullLog = [self.localStorage.debugLog ?? ""]
            let datePrefix = DateHelper.instance.formatDebug(date: self.dateProvider.currentDate)
            fullLog.append(datePrefix + " : " + log)

            self.localStorage.debugLog = fullLog.joined(separator: "|")
        }
    }

}

extension DebugLogger {

    var logs: [String] {
        let fullLog = localStorage.debugLog ?? ""

        return fullLog.split(separator: "|").map(String.init)
    }

    func logFinishLaunching() {
        updateLogs(with: "\n")
        updateLogs(with: "did finish launching")
    }

    func logEnterBackground() {
        updateLogs(with: "did enter background")
    }

    func logEnterForeground() {
        updateLogs(with: "\n")
        updateLogs(with: "will enter foreground")
    }

    func logTerminate() {
        updateLogs(with: "will terminate")
    }

    func add(log: String) {
        updateLogs(with: log)
    }

    func clearLogs() {
        localStorage.debugLog = nil
    }

}

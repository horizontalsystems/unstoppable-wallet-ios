class DebugLogger {
    private let localStorage: ILocalStorage
    private let dateProvider: ICurrentDateProvider

    init(localStorage: ILocalStorage, dateProvider: ICurrentDateProvider) {
        self.localStorage = localStorage
        self.dateProvider = dateProvider
    }

    private func updateLogs(with log: String) {
        var fullLog = [localStorage.debugLog ?? ""]
        let datePrefix = DateHelper.instance.formatDebug(date: dateProvider.currentDate)
        fullLog.append(datePrefix + " : " + log)

        localStorage.debugLog = fullLog.joined(separator: "|")
    }

}

extension DebugLogger: IDebugLogger {

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

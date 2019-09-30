class DebugBackgroundLogger {
    private let localStorage: ILocalStorage
    private let dateProvider: ICurrentDateProvider

    init(localStorage: ILocalStorage, dateProvider: ICurrentDateProvider) {
        self.localStorage = localStorage
        self.dateProvider = dateProvider
    }

    private func updateLogs(with log: String) {
        var fullLog = [localStorage.backgroundFetchLog ?? ""]
        let datePrefix = DateHelper.instance.formatDebug(date: dateProvider.currentDate)
        fullLog.append(datePrefix + " : " + log)

        localStorage.backgroundFetchLog = fullLog.joined(separator: "|")
    }

}

extension DebugBackgroundLogger: IDebugBackgroundLogger {

    var logs: [String] {
        let fullLog = localStorage.backgroundFetchLog ?? ""

        return fullLog.split(separator: "|").map(String.init)
    }

    func logFinishLaunching() {
        updateLogs(with: "did launching")
    }

    func logEnterBackground() {
        updateLogs(with: "did enter background")
    }

    func logEnterForeground() {
        updateLogs(with: "will enter foreground")
    }

    func logTerminate() {
        updateLogs(with: "will terminated")
    }

    func add(log: String) {
        updateLogs(with: log)
    }

    func clearLogs() {
        localStorage.backgroundFetchLog = nil
    }

}

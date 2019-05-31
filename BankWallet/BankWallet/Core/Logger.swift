import Foundation

class Logger {
    static let instance = Logger(minLogLevel: .error)

    enum Level: Int {
        case verbose = 0
        case debug = 1
        case info = 2
        case warning = 3
        case error = 4
    }

    private let colors: [Level: String] = [
        Level.verbose: "💜 VERBOSE ",
        Level.debug:   "💚 DEBUG ",
        Level.info:    "💙 INFO ",
        Level.warning: "💛 WARNING ",
        Level.error:   "❤️ ERROR "
    ]

    private lazy var dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.locale = Locale.current
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    private let minLogLevel: Level

    init(minLogLevel: Level) {
        self.minLogLevel = minLogLevel
    }

    private let includeFiles: [String] = []
    private let excludeFiles: [String] = []

    /// log something generally unimportant (lowest priority)
    func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .verbose, message: message(), file: file, function: function, line: line, context: context)
    }

    /// log something which help during debugging (low priority)
    func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .debug, message: message(), file: file, function: function, line: line, context: context)
    }

    /// log something which you are really interested but which is not an issue or error (normal priority)
    func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .info, message: message(), file: file, function: function, line: line, context: context)
    }

    /// log something which may cause big trouble soon (high priority)
    func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .warning, message: message(), file: file, function: function, line: line, context: context)
    }

    /// log something which will keep you awake at night (highest priority)
    func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, line: Int = #line, context: Any? = nil) {
        log(level: .error, message: message(), file: file, function: function, line: line, context: context)
    }

    /// custom logging to manually adjust values, should just be used by other frameworks
    func log(level: Logger.Level, message: @autoclosure () -> Any, file: String = #file, function: String = #function, line: Int = #line, context: Any? = nil) {
        guard level.rawValue >= minLogLevel.rawValue else {
            return
        }

        let file = fileNameWithoutSuffix(file)

        guard includeFiles.isEmpty || includeFiles.contains(file) else {
            return
        }

        guard excludeFiles.isEmpty || !excludeFiles.contains(file) else {
            return
        }

        var str = "\(dateFormatter.string(from: Date())) \(colors[level]!)"

        if let context = context {
            str = str + " \(context)"
        }

//        str = str + " \(file).\(functionName(function)):\(line) - \(message())"
        str = str + "\(message())"

        print(str)
    }

    private func functionName(_ function: String) -> String {
        if let index = function.firstIndex(of: "(") {
            return String(function.prefix(index.utf16Offset(in: function)))
        } else {
            return function
        }
    }

    // returns the current thread name
    private func threadName() -> String {
        if Thread.isMainThread {
            return ""
        } else {
            let threadName = Thread.current.name
            if let threadName = threadName, !threadName.isEmpty {
                return threadName
            } else {
                return String(format: "%p", Thread.current)
            }
        }
    }

    // returns the filename without suffix (= file ending) of a path
    private func fileNameWithoutSuffix(_ file: String) -> String {
        let fileName = fileNameOfFile(file)

        if !fileName.isEmpty {
            let fileNameParts = fileName.components(separatedBy: ".")
            if let firstPart = fileNameParts.first {
                return firstPart
            }
        }
        return ""
    }

    // returns the filename of a path
    private func fileNameOfFile(_ file: String) -> String {
        let fileParts = file.components(separatedBy: "/")
        if let lastPart = fileParts.last {
            return lastPart
        }
        return ""
    }

}

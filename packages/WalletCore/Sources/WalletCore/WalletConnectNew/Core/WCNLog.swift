import Combine
import Foundation

// Temporary smoke-test trace, removed before the module ships
enum WCNLog {
    static var cancellables = Set<AnyCancellable>()
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func log(_ message: String) {
        print("[WC] \(formatter.string(from: Date())) \(message)")
    }
}

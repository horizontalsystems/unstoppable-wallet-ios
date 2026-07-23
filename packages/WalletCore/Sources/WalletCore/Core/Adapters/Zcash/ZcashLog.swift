import Foundation
import os

// one-shot testnet/mainnet migration run telemetry; DEBUG builds only.
// os_log stream survives detached launches (kill + relaunch from home screen),
// unlike print/stdout which is visible only under the Xcode debugger.
enum ZcashLog {
    private static let osLog = os.Logger(subsystem: "zcash.smoke", category: "migration")

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    static func log(_ category: String, _ message: String) {
        #if DEBUG
            let line = "\(formatter.string(from: Date())) [\(category)] \(message)"
            print("[ZCASH] \(line)")
            osLog.info("\(line, privacy: .public)")
        #endif
    }
}

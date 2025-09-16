import Foundation

enum AdapterState: Hashable {
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case customSyncing(main: String, secondary: String?, progress: Int?)
    case connecting
    case notSynced(error: String)
    case stopped

    var isSynced: Bool {
        switch self {
        case .synced: return true
        default: return false
        }
    }

    var isNotSynced: Bool {
        switch self {
        case .notSynced: return true
        default: return false
        }
    }

    var syncing: Bool {
        switch self {
        case .connecting, .syncing, .customSyncing: return true
        default: return false
        }
    }
}

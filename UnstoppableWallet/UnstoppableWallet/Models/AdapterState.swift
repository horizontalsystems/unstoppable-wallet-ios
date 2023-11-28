import Foundation

enum AdapterState {
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case customSyncing(main: String, secondary: String?, progress: Int?)
    case notSynced(error: Error)
    case stopped

    var isSynced: Bool {
        switch self {
        case .synced: return true
        default: return false
        }
    }

    var syncing: Bool {
        switch self {
        case .syncing, .customSyncing: return true
        default: return false
        }
    }

    func spendAllowed(beforeSync: Bool) -> Bool {
        switch self {
        case .synced: return true
        case .syncing, .customSyncing: return beforeSync ? true : false
        case .stopped, .notSynced: return false
        }
    }
}

extension AdapterState: Equatable {
    public static func == (lhs: AdapterState, rhs: AdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case let (.syncing(lProgress, lLastBlockDate), .syncing(rProgress, rLastBlockDate)): return lProgress == rProgress && lLastBlockDate == rLastBlockDate
        case let (.customSyncing(lMain, lSecondary, lProgress), .customSyncing(rMain, rSecondary, rProgress)): return lMain == rMain && lSecondary == rSecondary && lProgress == rProgress
        case (.notSynced, .notSynced): return true
        case (.stopped, .stopped): return true
        default: return false
        }
    }
}

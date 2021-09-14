import Foundation

enum AdapterState {
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case searchingTxs(count: Int)
    case notSynced(error: Error)

    var isSynced: Bool {
        switch self {
        case .synced: return true
        default: return false
        }
    }

}

extension AdapterState: Equatable {
    public static func ==(lhs: AdapterState, rhs: AdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case (.syncing(let lProgress, let lLastBlockDate), .syncing(let rProgress, let rLastBlockDate)): return lProgress == rProgress && lLastBlockDate == rLastBlockDate
        case (.searchingTxs(let lCount), .searchingTxs(let rCount)): return lCount == rCount
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }
}

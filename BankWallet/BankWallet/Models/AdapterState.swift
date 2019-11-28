import Foundation

enum AdapterState {
    case synced
    case syncing(progress: Int, lastBlockDate: Date?)
    case notSynced

}

extension AdapterState: Equatable {
    public static func ==(lhs: AdapterState, rhs: AdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.synced, .synced): return true
        case (.syncing(let lProgress, let lLastBlockDate), .syncing(let rProgress, let rLastBlockDate)): return lProgress == rProgress && lLastBlockDate == rLastBlockDate
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }
}

import Foundation

enum AdapterState {
    case synced
    case syncing(progress: Int?, lastBlockDate: Date?)
    case searchingTxs(count: Int)
    case zCash(state: ZCashAdapterState)
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
        case (.zCash(let lState), .zCash(let rState)): return lState == rState
        case (.notSynced, .notSynced): return true
        default: return false
        }
    }
}

enum ZCashAdapterState: Equatable {
    case downloadingSapling(progress: Int)
    case downloadingBlocks(number: Int, lastBlock: Int)
    case scanningBlocks(number: Int, lastBlock: Int)
    case enhancingTransactions(number: Int, count: Int)

    public static func ==(lhs: ZCashAdapterState, rhs: ZCashAdapterState) -> Bool {
        switch (lhs, rhs) {
        case (.downloadingSapling(let lProgress), .downloadingSapling(let rProgress)): return lProgress == rProgress
        case (.downloadingBlocks(let lNumber, let lLast), .downloadingBlocks(let rNumber, let rLast)): return lNumber == rNumber && lLast == rLast
        case (.scanningBlocks(let lNumber, let lLast), .scanningBlocks(let rNumber, let rLast)): return lNumber == rNumber && lLast == rLast
        case (.enhancingTransactions(let lNumber, let lCount), .enhancingTransactions(let rNumber, let rCount)): return lNumber == rNumber && lCount == rCount
        default: return false
        }
    }
}
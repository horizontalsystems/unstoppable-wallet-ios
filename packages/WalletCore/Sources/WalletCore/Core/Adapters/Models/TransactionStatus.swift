import Foundation

public enum TransactionStatus {
    case failed
    case pending
    case processing(progress: Double)
    case completed

    public var isPendingOrProcessing: Bool {
        switch self {
        case .pending, .processing: return true
        default: return false
        }
    }

    public var isPending: Bool {
        switch self {
        case .pending: return true
        default: return false
        }
    }
}

extension TransactionStatus: Equatable {
    public static func == (lhs: TransactionStatus, rhs: TransactionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.failed, .failed): return true
        case (.pending, .pending): return true
        case let (.processing(lhsProgress), .processing(rhsProgress)): return lhsProgress == rhsProgress
        case (.completed, .completed): return true
        default: return false
        }
    }
}

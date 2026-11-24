import Foundation

public enum FeePriority: Sendable {
    case standard
    case priority
}

public protocol IFeePriorityConfigurable: AnyObject {
    /// Called once by `TransactionServiceFactory` right after the service is created and before the first `sync()`.
    /// Must not be called later: the service does not synchronize access to its fee priority.
    func set(feePriority: FeePriority)
}

public extension SendData {
    /// The single definition of which transactions get a fast-inclusion network fee by default.
    var feePriority: FeePriority {
        switch self {
        case .swap, .splitSwap, .privateSend, .crossPay: return .priority
        default: return .standard
        }
    }
}

import Foundation

/// Off-chain state of a GasFree submitTransfer authorization, per gasfree.io spec §5
/// (POST /api/v1/gasfree/submit + GET /api/v1/gasfree/{traceId}). Wire-format strings
/// are kept inside `unknown(...)` so a server-side state-machine extension does not crash
/// the client — UI treats unknown as a non-terminal placeholder.
enum GasFreeTransferState: Equatable {
    case waiting
    case inProgress
    case confirming
    case succeeded
    case failed
    case unknown(String)

    init(rawString: String) {
        switch rawString {
        case "WAITING": self = .waiting
        case "INPROGRESS": self = .inProgress
        case "CONFIRMING": self = .confirming
        case "SUCCEED": self = .succeeded
        case "FAILED": self = .failed
        default: self = .unknown(rawString)
        }
    }

    var rawString: String {
        switch self {
        case .waiting: return "WAITING"
        case .inProgress: return "INPROGRESS"
        case .confirming: return "CONFIRMING"
        case .succeeded: return "SUCCEED"
        case .failed: return "FAILED"
        case let .unknown(raw): return raw
        }
    }

    var isTerminal: Bool {
        switch self {
        case .succeeded, .failed: return true
        case .waiting, .inProgress, .confirming, .unknown: return false
        }
    }
}

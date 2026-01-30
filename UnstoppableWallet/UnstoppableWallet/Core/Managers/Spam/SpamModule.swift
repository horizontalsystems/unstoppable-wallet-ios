import Foundation
import HsToolKit
import MarketKit

protocol SpamFilter {
    var identifier: String { get }
    func evaluate(_ transaction: SpamTransactionInfo) -> SpamFilterResult
}

protocol SpamCondition {
    var identifier: String { get }
    /// Synchronous condition evaluation. Returns score.
    func evaluate(_ context: SpamEvaluationContext) -> Int
}

struct CachedOutputTransaction {
    let address: String
    let timestamp: Int
    let blockHeight: Int?
}

struct SpamTransactionInfo {
    let hash: String
    let blockchainType: BlockchainType
    let timestamp: Int
    let blockHeight: Int?
    let events: TransferEvents
}

enum SpamFilterResult {
    case ignore    // Filter not applicable, pass to next
    case spam      // Definitely spam, stop chain
    case trusted   // Definitely not spam, stop chain
}

enum SpamDecision {
    case spam
    case trusted
    case suspicious(score: Int)
}

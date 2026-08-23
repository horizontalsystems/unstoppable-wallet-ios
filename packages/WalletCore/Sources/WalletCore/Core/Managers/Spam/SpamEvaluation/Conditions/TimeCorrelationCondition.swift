import Foundation
import HsToolKit

// Proximity to any counterparty in the window, most recent first; block distance is checked
// before time for each entry, and the first entry within either threshold decides
class TimeCorrelationCondition: SpamCondition {
    var identifier: String { "time_correlation" }

    private let cache: OutputTransactionCache
    private let blockThreshold: Int
    private let timeThresholdMinutes: Int
    private let blockScore: Int
    private let timeScore: Int
    private let logger: Logger?

    init(
        cache: OutputTransactionCache,
        blockThreshold: Int = 5,
        timeThresholdMinutes: Int = 20,
        blockScore: Int = 4,
        timeScore: Int = 3,
        logger: Logger? = nil
    ) {
        self.cache = cache
        self.blockThreshold = blockThreshold
        self.timeThresholdMinutes = timeThresholdMinutes
        self.blockScore = blockScore
        self.timeScore = timeScore
        self.logger = logger
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        let transaction = context.transaction
        let thresholdSeconds = timeThresholdMinutes * 60

        guard !transaction.events.incoming.isEmpty else {
            return 0
        }

        for cached in cache.get(blockchainType: transaction.blockchainType) {
            if let cachedBlock = cached.blockHeight, let txBlock = transaction.blockHeight,
               abs(txBlock - cachedBlock) <= blockThreshold
            {
                return blockScore
            }

            if abs(transaction.timestamp - cached.timestamp) <= thresholdSeconds {
                return timeScore
            }
        }

        return 0
    }
}

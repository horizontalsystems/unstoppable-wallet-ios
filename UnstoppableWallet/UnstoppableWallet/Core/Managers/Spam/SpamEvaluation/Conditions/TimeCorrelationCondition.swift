import Foundation
import HsToolKit

class TimeCorrelationCondition: SpamCondition {
    var identifier: String { "time_correlation" }

    private let blockThreshold: Int
    private let timeThresholdMinutes: Int
    private let blockScore: Int
    private let timeScore: Int
    private let logger: Logger?

    init(
        blockThreshold: Int = 5,
        timeThresholdMinutes: Int = 20,
        blockScore: Int = 4,
        timeScore: Int = 3,
        logger: Logger? = nil
    ) {
        self.blockThreshold = blockThreshold
        self.timeThresholdMinutes = timeThresholdMinutes
        self.blockScore = blockScore
        self.timeScore = timeScore
        self.logger = logger
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        let matchedTimestamp: Int? = context.get(SpamContextKeys.matchedTimestamp)
        let matchedBlockHeight: Int? = context.get(SpamContextKeys.matchedBlockHeight)

        guard matchedTimestamp != nil || matchedBlockHeight != nil else {
            return 0
        }

        // Check block correlation first (more precise)
        if let matchedBlock = matchedBlockHeight,
           let txBlock = context.transaction.blockHeight
        {
            let blockDiff = abs(txBlock - matchedBlock)
            if blockDiff < blockThreshold {
                return blockScore
            }
        }

        // Fall back to time correlation
        if let matchedTime = matchedTimestamp {
            let timeDiff = abs(context.transaction.timestamp - matchedTime)
            let thresholdSeconds = timeThresholdMinutes * 60
            if timeDiff < thresholdSeconds {
                return timeScore
            }
        }

        return 0
    }
}

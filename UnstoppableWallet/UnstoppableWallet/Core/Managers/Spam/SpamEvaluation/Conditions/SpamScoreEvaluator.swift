import Foundation
import HsToolKit

final class SpamScoreEvaluator {
    private var conditions: [SpamCondition]
    private let spamThreshold: Int
    private let suspiciousThreshold: Int
    private let logger: Logger?

    init(
        conditions: [SpamCondition] = [],
        spamThreshold: Int = 7,
        suspiciousThreshold: Int = 3,
        logger: Logger? = nil
    ) {
        self.conditions = conditions
        self.spamThreshold = spamThreshold
        self.suspiciousThreshold = suspiciousThreshold
        self.logger = logger
    }

    @discardableResult
    func append(_ condition: SpamCondition) -> Self {
        conditions.append(condition)
        return self
    }

    /// Synchronous evaluation of all conditions
    func evaluate(_ context: SpamEvaluationContext) -> SpamDecision {
        var totalScore = 0

        for condition in conditions {
            let score = condition.evaluate(context)
            totalScore += score

            // Early exit if already spam
            if totalScore >= spamThreshold {
                logger?.log(level: .debug, message: "SSEvaluator: early exit, score=\(totalScore) >= threshold=\(spamThreshold)")
                return .spam
            }
        }

        let decision: SpamDecision
        if totalScore >= spamThreshold {
            decision = .spam
        } else if totalScore >= suspiciousThreshold {
            decision = .suspicious(score: totalScore)
        } else {
            decision = .trusted
        }

        logger?.log(level: .debug, message: "SSEvaluator: total=\(totalScore), decision=\(decision)")
        return decision
    }
}

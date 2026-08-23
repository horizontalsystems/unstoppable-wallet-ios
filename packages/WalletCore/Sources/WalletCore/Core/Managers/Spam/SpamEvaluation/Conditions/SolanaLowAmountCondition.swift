import Foundation
import HsToolKit

// Mirrors Android's Solana value scoring: per-event maximum, never a signed native aggregate.
// Zero-value coin transfers are instant spam; token legs score by absolute value, while
// negative (outgoing) native legs never score — matching the Android converter's data shape.
class SolanaLowAmountCondition: SpamCondition {
    var identifier: String { "solana_low_amount" }

    private let spamScore: Int
    private let riskScore: Int
    private let dangerScore: Int
    private let logger: Logger?

    init(spamScore: Int = 7, riskScore: Int = 3, dangerScore: Int = 2, logger: Logger? = nil) {
        self.spamScore = spamScore
        self.riskScore = riskScore
        self.dangerScore = dangerScore
        self.logger = logger
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        var maxScore = 0

        let allEvents = context.transaction.events.incoming + context.transaction.events.outgoing

        for event in allEvents {
            let score = evaluateEvent(event)
            if score >= spamScore {
                return spamScore
            }
            maxScore = max(maxScore, score)
        }

        return maxScore
    }

    private func evaluateEvent(_ event: TransferEvent) -> Int {
        switch event.value.kind {
        case .nft:
            return event.value.value > 0 ? 0 : riskScore
        case .raw, .eip20Token:
            return spamScore
        default:
            if event.value.value == 0 {
                return spamScore
            }
            if event.value.kind.token?.type.isNative ?? false {
                guard event.value.value > 0 else {
                    return 0
                }
                return evaluateWithLimits(code: event.value.code, value: event.value.value)
            }
            return evaluateWithLimits(code: event.value.code, value: abs(event.value.value))
        }
    }

    private func evaluateWithLimits(code: String, value: Decimal) -> Int {
        guard let limit = LowAmountCondition.defaultLimits[code] else {
            return 0
        }

        if value < limit.spam {
            return spamScore
        } else if value < limit.risk {
            return riskScore
        } else if value < limit.danger {
            return dangerScore
        }

        return 0
    }
}

import Foundation
import HsToolKit

class LowAmountCondition: SpamCondition {
    var identifier: String { "low_amount" }

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
        var nativeTotal: Decimal = 0
        var nativeCode: String?

        let allEvents = context.transaction.events.incoming + context.transaction.events.outgoing

        for event in allEvents {
            if event.value.kind.token?.type.isNative ?? false {
                nativeTotal += event.value.value
                nativeCode = event.value.code
            } else {
                let score = evaluateEvent(event)
                if score >= spamScore {
                    return spamScore
                }
                maxScore = max(maxScore, score)
            }
        }

        if let nativeCode {
            let score = evaluateWithLimits(code: nativeCode, value: nativeTotal)
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
            return evaluateWithLimits(code: event.value.code, value: event.value.value)
        }
    }

    private func evaluateWithLimits(code: String, value: Decimal) -> Int {
        guard let limit = Self.defaultLimits[code] else {
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

extension LowAmountCondition {
    static let defaultLimits: [String: AmountLimit] = [
        "XLM": .init(0.1),
        "USDT": .init(1),
        "USDC": .init(1),
        "USDD": .init(1),
        "DAI": .init(1),
        "BUSD": .init(1),
        "EURS": .init(1),
        "BSC-USD": .init(1),
        "TRX": .init(1),
        "ETH": .init(0.0005),
    ]

    struct AmountLimit {
        let spam: Decimal
        let risk: Decimal
        let danger: Decimal

        init(_ default: Decimal) {
            spam = `default` / 10
            risk = `default`
            danger = `default` * 5
        }
    }
}

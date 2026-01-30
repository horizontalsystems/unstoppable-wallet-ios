import Foundation
import HsToolKit

class LowAmountCondition: SpamCondition {
    var identifier: String { "low_amount" }

    private let dangerScore: Int
    private let riskScore: Int
    private let logger: Logger?

    init(dangerScore: Int = 7, riskScore: Int = 2, logger: Logger? = nil) {
        self.dangerScore = dangerScore
        self.riskScore = riskScore
        self.logger = logger
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        var maxScore = 0

        for event in context.transaction.events.incoming {
            let score = evaluateEvent(event)
            if score > maxScore {
                maxScore = score
            }
        }

        logger?.log(level: .debug, message: "LACondition: score=\(maxScore)")
        return maxScore
    }

    private func evaluateEvent(_ event: TransferEvent) -> Int {
        let value = event.value.value

        switch event.value.kind {
        case let .token(token):
            return evaluateWithLimits(code: token.coin.code, value: value)
        case let .coin(coin, _):
            return evaluateWithLimits(code: coin.code, value: value)
        case let .jetton(jetton):
            return evaluateWithLimits(code: jetton.symbol, value: value)
        case let .stellar(asset):
            return evaluateWithLimits(code: asset.code, value: value)
        case .nft:
            return value > 0 ? 0 : riskScore
        case .raw, .eip20Token:
            return dangerScore
        }
    }

    private func evaluateWithLimits(code: String, value: Decimal) -> Int {
        guard let limit = Self.defaultLimits[code] else {
            return 0
        }

        if value < limit.danger {
            return dangerScore
        } else if value < limit.risk {
            return riskScore
        }

        return 0
    }
}

extension LowAmountCondition {
    static let defaultLimits: [String: AmountLimit] = [
        "XLM": AmountLimit(danger: 0.01, risk: 0.05),
        "USDT": AmountLimit(danger: 1, risk: 2),
        "USDC": AmountLimit(danger: 1, risk: 2),
        "USDD": AmountLimit(danger: 1, risk: 2),
        "DAI": AmountLimit(danger: 1, risk: 2),
        "BUSD": AmountLimit(danger: 1, risk: 2),
        "EURS": AmountLimit(danger: 1, risk: 2),
        "BSC-USD": AmountLimit(danger: 1, risk: 2),
        "TRX": AmountLimit(danger: 0.1, risk: 0.2),
        "ETH": AmountLimit(danger: 0.0005, risk: 0.001),
    ]

    struct AmountLimit {
        let danger: Decimal
        let risk: Decimal
    }
}

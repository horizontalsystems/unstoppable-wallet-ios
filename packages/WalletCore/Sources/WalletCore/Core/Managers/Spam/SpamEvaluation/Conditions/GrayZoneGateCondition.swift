import Foundation

// Android's two-pass scoring: the value score alone decides when it is conclusive
// (0 → trusted, ≥ spam → spam); correlation runs only for the gray zone in between
final class GrayZoneGateCondition: SpamCondition {
    var identifier: String { "gray_zone_gate" }

    private let value: SpamCondition
    private let correlation: [SpamCondition]
    private let spamThreshold: Int

    init(value: SpamCondition, correlation: [SpamCondition], spamThreshold: Int = 7) {
        self.value = value
        self.correlation = correlation
        self.spamThreshold = spamThreshold
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        let valueScore = value.evaluate(context)

        guard valueScore > 0, valueScore < spamThreshold else {
            return valueScore
        }

        return correlation.reduce(valueScore) { $0 + $1.evaluate(context) }
    }
}

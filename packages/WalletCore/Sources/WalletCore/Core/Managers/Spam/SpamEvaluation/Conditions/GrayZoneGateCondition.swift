import Foundation

// Android's two-pass scoring: the value score alone decides when it is conclusive
// (0 → trusted, ≥ spam → spam); correlation runs only for the gray zone in between
final class GrayZoneGateCondition: SpamCondition {
    var identifier: String { "gray_zone_gate" }

    private let values: [SpamCondition]
    private let correlation: [SpamCondition]
    private let spamThreshold: Int

    // several value conditions add up, as Android's value pass adds the zero-value and dust points
    init(values: [SpamCondition], correlation: [SpamCondition], spamThreshold: Int = 7) {
        self.values = values
        self.correlation = correlation
        self.spamThreshold = spamThreshold
    }

    convenience init(value: SpamCondition, correlation: [SpamCondition], spamThreshold: Int = 7) {
        self.init(values: [value], correlation: correlation, spamThreshold: spamThreshold)
    }

    func evaluate(_ context: SpamEvaluationContext) -> Int {
        let valueScore = values.reduce(0) { $0 + $1.evaluate(context) }

        guard valueScore > 0, valueScore < spamThreshold else {
            return valueScore
        }

        return correlation.reduce(valueScore) { $0 + $1.evaluate(context) }
    }
}

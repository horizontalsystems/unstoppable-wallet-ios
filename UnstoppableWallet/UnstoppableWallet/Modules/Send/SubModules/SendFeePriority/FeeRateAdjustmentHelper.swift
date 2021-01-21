import Foundation

class FeeRateAdjustmentHelper {

    private let rules: [CoinType: [(amountRange: Range<Decimal>?, coefficient: Double)]] = [
        .bitcoin: [
            (amountRange: 10000..<Decimal.greatestFiniteMagnitude, coefficient: 1.25),
            (amountRange: 5000..<10000, coefficient: 1.20),
            (amountRange: 1000..<5000,  coefficient: 1.15),
            (amountRange: 500..<1000, coefficient: 1.10),
            (amountRange: 0..<500, coefficient: 1.05),
            (amountRange: nil, coefficient: 1.10)
        ],
        .ethereum: [
            (amountRange: 10000..<Decimal.greatestFiniteMagnitude, coefficient: 1.25),
            (amountRange: 5000..<10000, coefficient: 1.20),
            (amountRange: 1000..<5000,  coefficient: 1.15),
            (amountRange: 500..<1000, coefficient: 1.10),
            (amountRange: 0..<500, coefficient: 1.05),
            (amountRange: nil, coefficient: 1.10)
        ]
    ]

    func applyRule(coinType: CoinType, amount: Decimal?, feeRate: Int) -> Int {
        guard let rules = rules[coinType] else {
            return feeRate
        }

        var coefficient = 1.0

        if let amount = amount {
            if let rule = rules.first(where: { $0.amountRange?.contains(amount) ?? false }) {
                coefficient = rule.coefficient
            }
        } else {
            if let rule = rules.first(where: { $0.amountRange == nil }) {
                coefficient = rule.coefficient
            }
        }

        return Int((Double(feeRate) * coefficient).rounded())
    }

}

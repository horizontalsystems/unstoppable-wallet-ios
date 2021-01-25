import Foundation
import CurrencyKit

class FeeRateAdjustmentHelper {
    typealias Rule = (amountRange: Range<Decimal>, coefficient: Double)

    private let allowedCurrencyCodes: [String]
    private let fallbackCoefficient = 1.1
    private let rules: [CoinType: [Rule]] = [
        .bitcoin: [
            (amountRange: 10000..<Decimal.greatestFiniteMagnitude, coefficient: 1.25),
            (amountRange: 5000..<10000, coefficient: 1.20),
            (amountRange: 1000..<5000,  coefficient: 1.15),
            (amountRange: 500..<1000, coefficient: 1.10),
            (amountRange: 0..<500, coefficient: 1.05)
        ],
        .ethereum: [
            (amountRange: 10000..<Decimal.greatestFiniteMagnitude, coefficient: 1.25),
            (amountRange: 5000..<10000, coefficient: 1.20),
            (amountRange: 1000..<5000,  coefficient: 1.15),
            (amountRange: 200..<1000, coefficient: 1.11),
            (amountRange: 0..<200, coefficient: 1.05)
        ]
    ]

    init(currencyCodes: [String]) {
        allowedCurrencyCodes = currencyCodes
    }

    private func feeRateCoefficient(rules: [Rule], currencyValue: CurrencyValue?, feeRate: Int) -> Double {
        guard let currencyValue = currencyValue else {
            return fallbackCoefficient
        }

        guard allowedCurrencyCodes.contains(currencyValue.currency.code) else {
            return fallbackCoefficient
        }

        if let rule = rules.first(where: { $0.amountRange.contains(currencyValue.value) }) {
            return rule.coefficient
        }

        return fallbackCoefficient
    }

    func applyRule(coinType: CoinType, currencyValue: CurrencyValue?, feeRate: Int) -> Int {
        guard let rules = rules[coinType] else {
            return feeRate
        }

        let coefficient = feeRateCoefficient(rules: rules, currencyValue: currencyValue, feeRate: feeRate)

        return Int((Double(feeRate) * coefficient).rounded())
    }

}

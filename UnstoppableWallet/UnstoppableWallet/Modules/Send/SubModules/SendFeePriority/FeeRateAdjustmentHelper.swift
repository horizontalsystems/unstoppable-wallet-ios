import Foundation
import CurrencyKit
import MarketKit

class FeeRateAdjustmentHelper {
    typealias Rule = (amountRange: Range<Decimal>, coefficient: Double)

    private let allowedCurrencyCodes = ["USD", "EUR"]

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

    private func feeRateCoefficient(rules: [Rule], feeRateAdjustmentInfo: FeeRateAdjustmentInfo, feeRate: Int) -> Double {
        guard allowedCurrencyCodes.contains(feeRateAdjustmentInfo.currency.code) else {
            return fallbackCoefficient
        }

        var resolvedCoinAmount: Decimal? = nil
        switch feeRateAdjustmentInfo.amountInfo {
        case .max: resolvedCoinAmount = feeRateAdjustmentInfo.balance
        case .entered(let amount): resolvedCoinAmount = amount
        case .notEntered: resolvedCoinAmount = feeRateAdjustmentInfo.balance
        }
        guard let coinAmount = resolvedCoinAmount, let xRate = feeRateAdjustmentInfo.xRate else {
            return fallbackCoefficient
        }

        let fiatAmount = coinAmount * xRate

        if let rule = rules.first(where: { $0.amountRange.contains(fiatAmount) }) {
            return rule.coefficient
        }

        return fallbackCoefficient
    }

    func applyRule(coinType: CoinType, feeRateAdjustmentInfo: FeeRateAdjustmentInfo, feeRate: Int) -> Int {
        guard let rules = rules[coinType] else {
            return feeRate
        }

        let coefficient = feeRateCoefficient(rules: rules, feeRateAdjustmentInfo: feeRateAdjustmentInfo, feeRate: feeRate)

        return Int((Double(feeRate) * coefficient).rounded())
    }

}

import Foundation
import MarketKit
import SwiftUI

extension TechnicalAdvice {
    var mainAdvice: String {
        let overtype: String
        let direction: String
        let rsiLine: String

        switch advice ?? .neutral {
        case .oversold, .strongBuy, .buy:
            overtype = "technical_advice.over.sold".localized
            direction = "technical_advice.down".localized
            rsiLine = "30%"
        case .overbought, .strongSell, .sell, .neutral:
            overtype = "technical_advice.over.bought".localized
            direction = "technical_advice.up".localized
            rsiLine = "70%"
        }

        let rsiValue = rsi.flatMap { ValueFormatter.instance.format(percentValue: $0, signType: .never) }
        let signalTimeString = signalTimestamp.flatMap {
            let date = DateHelper.instance.formatShortDateOnly(date: Date(timeIntervalSince1970: $0))
            return "technical_advice.over.indicators.signal_date".localized(date)
        }

        switch advice {
        case .oversold, .overbought:
            let advice = "technical_advice.over.main".localized

            var rsi = ""
            if let rsiValue {
                rsi = "technical_advice.over.rsi".localized(rsiValue, overtype)
            }
            var indicators = "technical_advice.over.indicators".localized(overtype)
            indicators += rsi

            if let time = signalTimeString {
                indicators = [time, lowercasedFirst(indicators)].joined(separator: " ")
            }

            let resultAdvice = "technical_advice.over.advice".localized(direction)
            return advice + indicators + resultAdvice
        case .strongBuy, .strongSell:
            var rsi = ""
            if let rsiValue {
                rsi = "technical_advice.strong.rsi".localized(rsiValue, overtype)
            }

            var indicators = "technical_advice.strong.indicators".localized(overtype)
            if let time = signalTimeString {
                indicators = [time, lowercasedFirst(indicators)].joined(separator: " ")
            }

            indicators += rsi
            let resultAdvice = "technical_advice.strong.advice".localized(direction)
            return indicators + resultAdvice
        case .buy, .sell:
            var rsi = ""
            if let rsiValue {
                rsi = "technical_advice.stable.rsi".localized(rsiValue, rsiLine)
            }

            var indicators = "technical_advice.strong.indicators".localized(overtype)
            if let time = signalTimeString {
                indicators = [time, lowercasedFirst(indicators)].joined(separator: " ")
            }

            indicators += rsi
            let resultAdvice = "technical_advice.strong.advice".localized(direction)
            return indicators + resultAdvice
        case .neutral, .none:
            var rsi = ""
            if let rsiValue {
                rsi = "technical_advice.stable.rsi".localized(rsiValue)
            }

            var indicators = "technical_advice.neutral.indicators".localized(overtype)
            indicators += rsi
            if let time = signalTimeString {
                indicators = [time, lowercasedFirst(indicators)].joined(separator: " ")
            }

            let resultAdvice = "technical_advice.neutral.advice".localized
            return indicators + resultAdvice
        }
    }

    var trendAdvice: String? {
        guard let price else {
            return nil
        }

        let emaAdvice = ema.flatMap {
            let direction = price >= $0 ? "technical_advice.ema.above".localized : "technical_advice.ema.below".localized
            let action = price >= $0 ? "technical_advice.ema.growth".localized : "technical_advice.ema.decrease".localized

            let emaValue = ValueFormatter.instance.formatFull(value: $0, decimalCount: 8) ?? "---"
            return "technical_advice.ema.advice".localized(direction, emaValue, action)
        }

        let macdAdvice = macd.flatMap {
            let direction = $0 >= 0 ? "technical_advice.macd.positive".localized : "technical_advice.macd.negative".localized
            let action = $0 >= 0 ? "technical_advice.up".localized : "technical_advice.down".localized

            let macdValue = ValueFormatter.instance.formatFull(value: $0, decimalCount: 4) ?? "---"
            return "technical_advice.macd.advice".localized(direction, macdValue, action)
        }

        let advices = [emaAdvice, macdAdvice].compactMap { $0 }
        if advices.isEmpty {
            return nil
        }

        return (["technical_advice.other.title".localized] + advices).joined(separator: "\n\n")
    }

    private func lowercasedFirst(_ string: String) -> String {
        string.prefix(1).lowercased() + string.dropFirst()
    }
}

extension TechnicalAdvice.Advice {
    var title: String {
        switch self {
        case .oversold, .overbought: return "market.signal.risky".localized
        case .strongBuy: return "market.signal.strong_buy".localized
        case .buy: return "market.signal.buy".localized
        case .neutral: return "market.signal.neutral".localized
        case .sell: return "market.signal.sell".localized
        case .strongSell: return "market.signal.strong_sell".localized
        }
    }

    var colorStyle: ColorStyle {
        switch self {
        case .neutral: return .secondary
        case .buy, .strongBuy: return .green
        case .sell, .strongSell: return .red
        case .overbought, .oversold: return .yellow
        }
    }
}

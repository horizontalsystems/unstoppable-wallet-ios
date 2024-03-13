import Chart
import Combine
import Foundation
import MarketKit
import ThemeKit
import UIKit

class CoinIndicatorViewItemFactory {
    static let sectionNames = ["coin_analytics.indicators.summary".localized] + ChartIndicator.Category.allCases.map(\.title)

    private func advice(items: [TechnicalIndicatorService.Item]) -> Advice {
        let rating = items.map(\.advice.rating).reduce(0, +)
        let adviceCount = items.filter { $0.advice != .noData }.count
        let variations = 2 * adviceCount + 1

        let baseDelta = variations / 5
        let remainder = variations % 5
        let neutralAddict = remainder % 3 // how much variations will be added to neutral zone
        let sideAddict = remainder / 3 // how much will be added to sell/buy zone

        let deltas = [baseDelta, baseDelta + sideAddict, baseDelta + sideAddict + neutralAddict, baseDelta + sideAddict, baseDelta]

        var current = -adviceCount
        var ranges = [Range<Int>]()
        for delta in deltas {
            ranges.append(current ..< (current + delta))
            current += delta
        }
        let index = ranges.firstIndex { $0.contains(rating) } ?? 0

        return Advice(rawValue: index) ?? .neutral
    }
}

extension CoinIndicatorViewItemFactory {
    func viewItems(items: [TechnicalIndicatorService.SectionItem]) -> [ViewItem] {
        var viewItems = [ViewItem]()

        var allAdviceItems = [TechnicalIndicatorService.Item]()
        for item in items {
            allAdviceItems.append(contentsOf: item.items)
            viewItems.append(ViewItem(name: item.name, advice: advice(items: item.items)))
        }

        let viewItem = ViewItem(name: Self.sectionNames.first ?? "", advice: advice(items: allAdviceItems))
        if viewItems.count > 0 {
            viewItems.insert(viewItem, at: 0)
        }
        return viewItems
    }

    func detailViewItems(items: [TechnicalIndicatorService.SectionItem]) -> [SectionDetailViewItem] {
        items.map {
            SectionDetailViewItem(
                name: $0.name,
                viewItems: $0.items.map { DetailViewItem(name: $0.name, advice: $0.advice.title, color: $0.advice.color) }
            )
        }
    }

    func advice(technicalAdvice: TechnicalAdvice) -> String {
        var main = mainAdvice(technicalAdvice)
        if let trend = trendAdvice(technicalAdvice) {
            main = String([main, trend].joined(separator: "\n\n"))
        }

        return main
    }

    private func capitalizedFirst(_ string: String) -> String {
        string.prefix(1).uppercased() + string.dropFirst()
    }

    private func mainAdvice(_ technicalAdvice: TechnicalAdvice) -> String {
        let overtype: String
        let direction: String
        let rsiLine: String

        switch technicalAdvice.advice ?? .neutral {
        case .oversold, .strongBuy, .buy:
            overtype = "technical_advice.over.sold".localized
            direction = "technical_advice.down".localized
            rsiLine = "30%"
        case .overbought, .strongSell, .sell, .neutral:
            overtype = "technical_advice.over.sold".localized
            direction = "technical_advice.down".localized
            rsiLine = "70%"
        }

        let rsiValue = technicalAdvice.rsi.flatMap { ValueFormatter.instance.format(percentValue: $0, showSign: false) }
        let signalTimeString = technicalAdvice.signalTimestamp.flatMap {
            let date = DateHelper.instance.formatShortDateOnly(date: Date(timeIntervalSince1970: $0))
            return "technical_advice.over.indicators.signal_date".localized(date)
        }

        switch technicalAdvice.advice {
        case .oversold, .overbought:
            let advice = "technical_advice.over.main".localized

            var rsi = ""
            if let rsiValue {
                rsi = "technical_advice.over.rsi".localized(rsiValue, overtype)
            }
            var indicators = "technical_advice.over.indicators".localized(overtype)
            indicators += rsi

            if let time = signalTimeString {
                indicators = [time, capitalizedFirst(indicators)].joined(separator: " ")
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
                indicators = [time, capitalizedFirst(indicators)].joined(separator: " ")
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
                indicators = [time, capitalizedFirst(indicators)].joined(separator: " ")
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
                indicators = [time, capitalizedFirst(indicators)].joined(separator: " ")
            }

            let resultAdvice = "technical_advice.neutral.advice".localized
            return indicators + resultAdvice
        }
    }

    private func trendAdvice(_ technicalAdvice: TechnicalAdvice) -> String? {
        guard let price = technicalAdvice.price else {
            return nil
        }

        let emaAdvice = technicalAdvice.ema.flatMap {
            let direction = price >= $0 ? "technical_advice.ema.above".localized : "technical_advice.ema.below".localized
            let action = price >= $0 ? "technical_advice.ema.growth".localized : "technical_advice.ema.decrease".localized

            let emaValue = ValueFormatter.instance.formatFull(value: $0, decimalCount: 8) ?? "---"
            return "technical_advice.ema.advice".localized(direction, emaValue, action)
        }

        let macdAdvice = technicalAdvice.macd.flatMap {
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
}

extension TechnicalAdvice.Advice {
    var title: String {
        switch self {
        case .oversold: return "coin_analytics.indicators.oversold".localized
        case .strongBuy: return "coin_analytics.indicators.strong_buy".localized
        case .buy: return "coin_analytics.indicators.buy".localized
        case .neutral: return "coin_analytics.indicators.neutral".localized
        case .sell: return "coin_analytics.indicators.sell".localized
        case .strongSell: return "coin_analytics.indicators.strong_sell".localized
        case .overbought: return "coin_analytics.indicators.overbought".localized
        }
    }

    var sliderIndex: Int {
        switch self {
        case .oversold: return 0
        case .strongBuy: return 3
        case .buy: return 2
        case .neutral: return 1
        case .sell: return 2
        case .strongSell: return 3
        case .overbought: return 0
        }
    }
}

extension CoinIndicatorViewItemFactory {
    enum Advice: Int, CaseIterable {
        case strongSell
        case sell
        case neutral
        case buy
        case strongBuy

        var color: UIColor {
            switch self {
            case .strongSell: return UIColor(hex: 0xF43A4F)
            case .sell: return UIColor(hex: 0xF4503A)
            case .neutral: return .themeJacob
            case .buy: return UIColor(hex: 0xB5C405)
            case .strongBuy: return .themeRemus
            }
        }

        var title: String {
            switch self {
            case .strongBuy: return "coin_analytics.indicators.strong_buy".localized
            case .buy: return "coin_analytics.indicators.buy".localized
            case .neutral: return "coin_analytics.indicators.neutral".localized
            case .sell: return "coin_analytics.indicators.sell".localized
            case .strongSell: return "coin_analytics.indicators.strong_sell".localized
            }
        }
    }

    struct ViewItem {
        let name: String
        let advice: Advice
    }

    struct DetailViewItem {
        let name: String
        let advice: String
        let color: UIColor
    }

    struct SectionDetailViewItem {
        let name: String
        let viewItems: [DetailViewItem]
    }
}

extension TechnicalIndicatorService.Advice {
    var title: String {
        switch self {
        case .noData: return "coin_analytics.indicators.no_data".localized
        case .buy: return "coin_analytics.indicators.buy".localized
        case .neutral: return "coin_analytics.indicators.neutral".localized
        case .sell: return "coin_analytics.indicators.sell".localized
        }
    }

    var color: UIColor {
        switch self {
        case .noData: return .themeGray
        case .buy: return CoinIndicatorViewItemFactory.Advice.buy.color
        case .neutral: return CoinIndicatorViewItemFactory.Advice.neutral.color
        case .sell: return CoinIndicatorViewItemFactory.Advice.sell.color
        }
    }
}

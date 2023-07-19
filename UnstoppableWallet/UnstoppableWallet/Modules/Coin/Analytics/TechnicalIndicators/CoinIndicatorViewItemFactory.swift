import Combine
import Foundation
import UIKit
import Chart
import ThemeKit

class CoinIndicatorViewItemFactory {
    static let sectionNames = ["coin_analytics.indicators.summary".localized] + ChartIndicator.Category.allCases.map { $0.title }

    private func advice(items: [TechnicalIndicatorService.Item]) -> Advice {
        let rating = items.map { $0.advice.rating }.reduce(0, +)
        let adviceCount = items.filter { $0.advice != .noData }.count
        let variations = 2 * adviceCount + 1

        let baseDelta = variations / 5
        let remainder = variations % 5
        let neutralAddict = remainder % 3   // how much variations will be added to neutral zone
        let sideAddict = remainder / 3 // how much will be added to sell/buy zone

        let deltas = [baseDelta, baseDelta + sideAddict, baseDelta + sideAddict + neutralAddict, baseDelta + sideAddict, baseDelta]

        var current = -adviceCount
        var ranges = [Range<Int>]()
        for delta in deltas {
            ranges.append(current..<(current + delta))
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

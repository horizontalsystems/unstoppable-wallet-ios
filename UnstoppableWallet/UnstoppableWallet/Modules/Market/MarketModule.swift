import Foundation
import UIKit
import ThemeKit
import CurrencyKit
import MarketKit
import ComponentKit
import StorageKit
import SectionsTableView
import Kingfisher

enum RowActionType {
    case additive
    case destructive

    var iconColor: UIColor {
        switch self {
        case .additive: return .themeDark
        case .destructive: return .themeClaude
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .additive: return .themeYellowD
        case .destructive: return .themeRedD
        }
    }
}

struct MarketModule {

    static func viewController() -> UIViewController {
        let service = MarketService(storage: StorageKit.LocalStorage.default, launchScreenManager: App.shared.launchScreenManager)
        let viewModel = MarketViewModel(service: service)
        return MarketViewController(viewModel: viewModel)
    }

    static func marketListCell(tableView: UITableView, backgroundStyle: BaseThemeCell.BackgroundStyle, listViewItem: MarketModule.ListViewItem, isFirst: Bool, isLast: Bool, rowActionProvider: (() -> [RowAction])?, action: (() -> ())?) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.imageView.contentMode = .scaleAspectFill
                        component.imageView.clipsToBounds = true
                        component.imageView.cornerRadius = listViewItem.iconShape.radius
                        component.imageView.layer.cornerCurve = .continuous
                        component.imageView.kf.setImage(
                                with: URL(string: listViewItem.iconUrl),
                                placeholder: UIImage(named: listViewItem.iconPlaceholderName),
                                options: [.onlyLoadFirstFrame]
                        )
                    },
                    .vStackCentered([
                        .hStack([
                            .text { component in
                                component.font = .body
                                component.textColor = .themeLeah
                                component.text = listViewItem.leftPrimaryValue
                            },
                            .text { component in
                                component.font = .body
                                component.textColor = .themeLeah
                                component.textAlignment = .right
                                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                                component.text = listViewItem.rightPrimaryValue
                            }
                        ]),
                        .margin(3),
                        .hStack([
                            .badge { component in
                                if let badge = listViewItem.badge {
                                    component.isHidden = false
                                    component.badgeView.set(style: .small)
                                    component.badgeView.text = badge
                                    component.badgeView.change = listViewItem.badgeSecondaryValue
                                } else {
                                    component.isHidden = true
                                }
                            },
                            .margin8,
                            .text { component in
                                component.font = .subhead2
                                component.textColor = .themeGray
                                component.text = listViewItem.leftSecondaryValue
                            },
                            .text { component in
                                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                                component.setContentHuggingPriority(.required, for: .horizontal)
                                component.textAlignment = .right
                                let marketFieldData = marketFieldPreference(dataValue: listViewItem.rightSecondaryValue)
                                component.font = .subhead2
                                component.textColor = marketFieldData.color
                                component.text = marketFieldData.value
                            }
                        ])
                    ])
                ]),
                tableView: tableView,
                id: "\(listViewItem.uid ?? "")-\(listViewItem.leftPrimaryValue)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                rowActionProvider: rowActionProvider,
                bind: { cell in
                    cell.set(backgroundStyle: backgroundStyle, isFirst: isFirst, isLast: isLast)
                },
                action: action
        )
    }

    static func marketFieldPreference(dataValue: MarketDataValue) -> (title: String?, value: String?, color: UIColor) {
        let title: String?
        let value: String?
        let color: UIColor

        switch dataValue {
        case .valueDiff(let currencyValue, let diff):
            title = nil

            if let currencyValue = currencyValue, let diff = diff {
                let valueDiff = diff * currencyValue.value / 100
                value = ValueFormatter.instance.formatShort(currency: currencyValue.currency, value: valueDiff, showSign: true) ?? "----"
                color = valueDiff.isSignMinus ? .themeLucian : .themeRemus
            } else {
                value = "----"
                color = .themeGray50
            }
        case .diff(let diff):
            title = nil
            value = diff.flatMap { ValueFormatter.instance.format(percentValue: $0) } ?? "----"
            if let diff = diff {
                color = diff.isSignMinus ? .themeLucian : .themeRemus
            } else {
                color = .themeGray50
            }
        case .volume(let volume):
            title = "market.top.volume.title".localized
            value = volume
            color = .themeGray
        case .marketCap(let marketCap):
            title = "market.top.market_cap.title".localized
            value = marketCap
            color = .themeGray
        }

        return (title: title, value: value, color: color)
    }

}

extension MarketModule {

    enum Tab: Int, CaseIterable {
        case overview
        case posts
        case watchlist

        var title: String {
            switch self {
            case .overview: return "market.category.overview".localized
            case .posts: return "market.category.posts".localized
            case .watchlist: return "market.category.watchlist".localized
            }
        }
    }

    enum SortingField: Int, CaseIterable {
        case highestCap
        case lowestCap
        case highestVolume
        case lowestVolume
        case topGainers
        case topLosers

        var title: String {
            switch self {
            case .highestCap: return "market.top.highest_cap".localized
            case .lowestCap: return "market.top.lowest_cap".localized
            case .highestVolume: return "market.top.highest_volume".localized
            case .lowestVolume: return "market.top.lowest_volume".localized
            case .topGainers: return "market.top.top_gainers".localized
            case .topLosers: return "market.top.top_losers".localized
            }
        }
    }

    enum MarketField: Int, CaseIterable {
        case price
        case marketCap
        case volume

        var title: String {
            switch self {
            case .price: return "price".localized
            case .marketCap: return "market.market_field.mcap".localized
            case .volume: return "market.market_field.vol".localized
            }
        }
    }

    enum MarketTop: Int, CaseIterable {
        case top100 = 100
        case top200 = 200
        case top300 = 300

        var title: String {
            "\(self.rawValue)"
        }
    }

    enum PriceChangeType: CaseIterable {
        case day
        case week
        case week2
        case month
        case month6
        case year

        var title: String {
            switch self {
            case .day: return "market.advanced_search.day".localized
            case .week: return "market.advanced_search.week".localized
            case .week2: return "market.advanced_search.week2".localized
            case .month: return "market.advanced_search.month".localized
            case .month6: return "market.advanced_search.month6".localized
            case .year: return "market.advanced_search.year".localized
            }
        }
    }

    enum MarketTvlField: Int, CaseIterable {
        case diff
        case value

        var title: String {
            switch self {
            case .value: return "market.tvl.market_field.value".localized
            case .diff: return "market.tvl.market_field.diff".localized
            }
        }
    }

    enum MarketPlatformField: Int, CaseIterable {
        case all
        case ethereum
        case solana
        case binance
        case avalanche
        case terra
        case fantom
        case arbitrum
        case polygon

        var chain: String {
            switch self {
            case .all: return ""
            case .ethereum: return "Ethereum"
            case .solana: return "Solana"
            case .binance: return "Binance"
            case .avalanche: return "Avalanche"
            case .terra: return "Terra"
            case .fantom: return "Fantom"
            case .arbitrum: return "Arbitrum"
            case .polygon: return "Polygon"
            }
        }

        var title: String {
            switch self {
            case .all: return "market.tvl.platform_field.all".localized
            default: return chain
            }
        }
    }

}

extension MarketKit.MarketInfo {

    func priceChangeValue(type: MarketModule.PriceChangeType) -> Decimal? {
        switch type {
        case .day: return priceChange24h
        case .week: return priceChange7d
        case .week2: return priceChange14d
        case .month: return priceChange30d
        case .month6: return priceChange200d
        case .year: return priceChange1y
        }
    }

}

extension Array where Element == MarketKit.MarketInfo {

    func sorted(sortingField: MarketModule.SortingField, priceChangeType: MarketModule.PriceChangeType) -> [MarketKit.MarketInfo] {
        sorted { lhsMarketInfo, rhsMarketInfo in
            switch sortingField {
            case .highestCap: return lhsMarketInfo.marketCap ?? 0 > rhsMarketInfo.marketCap ?? 0
            case .lowestCap: return lhsMarketInfo.marketCap ?? 0 < rhsMarketInfo.marketCap ?? 0
            case .highestVolume: return lhsMarketInfo.totalVolume ?? 0 > rhsMarketInfo.totalVolume ?? 0
            case .lowestVolume: return lhsMarketInfo.totalVolume ?? 0 < rhsMarketInfo.totalVolume ?? 0
            case .topGainers, .topLosers:
                guard let rhsPriceChange = rhsMarketInfo.priceChangeValue(type: priceChangeType) else {
                    return true
                }
                guard let lhsPriceChange = lhsMarketInfo.priceChangeValue(type: priceChangeType) else {
                    return false
                }

                return sortingField == .topGainers ? lhsPriceChange > rhsPriceChange : lhsPriceChange < rhsPriceChange
            }
        }
    }

}

extension MarketModule {  // ViewModel Items

    enum MarketDataValue {
        case valueDiff(CurrencyValue?, Decimal?)
        case diff(Decimal?)
        case volume(String)
        case marketCap(String)
    }

    struct ListViewItem {
        let uid: String?
        let iconUrl: String
        let iconShape: IconShape
        let iconPlaceholderName: String
        let leftPrimaryValue: String
        let leftSecondaryValue: String
        let badge: String?
        let badgeSecondaryValue: BadgeView.Change?
        let rightPrimaryValue: String
        let rightSecondaryValue: MarketDataValue
    }

    struct ListViewItemData {
        let viewItems: [ListViewItem]
        let softUpdate: Bool
        let scrollToTop: Bool

        init(viewItems: [ListViewItem], softUpdate: Bool = false, scrollToTop: Bool = false) {
            self.viewItems = viewItems
            self.softUpdate = softUpdate
            self.scrollToTop = scrollToTop
        }
    }

    enum IconShape {
        case square, round, full

        var radius: CGFloat {
            switch self {
            case .square: return .cornerRadius4
            case .round: return .cornerRadius12
            case .full: return 0
            }
        }

    }

}

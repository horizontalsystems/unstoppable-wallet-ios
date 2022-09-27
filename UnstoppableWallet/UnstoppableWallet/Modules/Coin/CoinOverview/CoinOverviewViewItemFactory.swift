import Foundation
import CurrencyKit
import MarketKit

class CoinOverviewViewItemFactory {

    private func roundedFormat(coinCode: String, value: Decimal?) -> String? {
        guard let value = value, !value.isZero, let formattedValue = ValueFormatter.instance.formatShort(value: value, decimalCount: 0, symbol: coinCode) else {
            return nil
        }

        return formattedValue
    }

    private func roiTitle(timePeriod: HsTimePeriod) -> String {
        switch timePeriod {
        case .day1: return "coin_page.roi.hour24".localized
        case .week1: return "coin_page.roi.day7".localized
        case .week2: return "coin_page.roi.day14".localized
        case .month1: return "coin_page.roi.day30".localized
        case .month6: return "coin_page.roi.day200".localized
        case .year1: return "coin_page.roi.year1".localized
        default: return "n/a".localized
        }
    }

    private func performanceViewItems(info: MarketInfoOverview) -> [[CoinOverviewViewModel.PerformanceViewItem]] {
        var viewItems = [[CoinOverviewViewModel.PerformanceViewItem]]()

        var titleRow = [CoinOverviewViewModel.PerformanceViewItem]()
        titleRow.append(.title("coin_page.return_of_investments".localized))

        var intervals = [HsTimePeriod]()
        for row in info.performance {
            for (interval, _) in row.changes {
                if !intervals.contains(interval) {
                    intervals.append(interval)
                }
            }
        }

        intervals.sort()
        intervals.forEach { titleRow.append(.subtitle(roiTitle(timePeriod: $0))) }

        viewItems.append(titleRow)

        info.performance.forEach { performanceRow in
            var row = [CoinOverviewViewModel.PerformanceViewItem]()
            row.append(.content("vs \(performanceRow.base.rawValue.uppercased())"))

            intervals.forEach { timePeriod in
                row.append(.value(performanceRow.changes[timePeriod]))
            }
            viewItems.append(row)
        }

        return viewItems
    }

    private func categories(info: MarketInfoOverview) -> [String]? {
        let categories = info.categories
        return categories.isEmpty ? nil : categories.map { $0.name }
    }

    private func explorerUrl(token: Token, reference: String) -> String? {
        guard let explorerUrl = token.blockchain.explorerUrl else {
            return nil
        }

        return explorerUrl.replacingOccurrences(of: "$ref", with: reference)
    }

    private func contractViewItems(info: MarketInfoOverview) -> [CoinOverviewViewModel.ContractViewItem]? {
        let tokens = info.fullCoin.tokens.sorted { lhsToken, rhsToken in
            lhsToken.blockchain.type.order < rhsToken.blockchain.type.order
        }

        let contracts: [CoinOverviewViewModel.ContractViewItem] = tokens.compactMap { token in
            switch token.type {
            case .eip20(let address):
                return CoinOverviewViewModel.ContractViewItem(iconUrl: token.blockchainType.imageUrl, title: address.shortened, reference: address, explorerUrl: explorerUrl(token: token, reference: address))
            case .bep2(let symbol):
                return CoinOverviewViewModel.ContractViewItem(iconUrl: token.blockchainType.imageUrl, title: symbol, reference: symbol, explorerUrl: explorerUrl(token: token, reference: symbol))
            case let .unsupported(_, reference):
                if let reference = reference {
                    return CoinOverviewViewModel.ContractViewItem(iconUrl: token.blockchainType.imageUrl, title: reference.shortened, reference: reference, explorerUrl: explorerUrl(token: token, reference: reference))
                } else {
                    return nil
                }
            default: return nil
            }
        }

        return contracts.isEmpty ? nil : contracts
    }

    private func linkTitle(type: LinkType, url: String) -> String {
        switch type {
        case .website:
            if let url = URL(string: url), let host = url.host {
                return host.stripping(prefix: "www.")
            } else {
                return "coin_page.website".localized
            }
        case .whitepaper: return "coin_page.whitepaper".localized
        case .reddit: return "Reddit"
        case .twitter: return url.stripping(prefix: "https://twitter.com/")
        case .telegram: return "Telegram"
        case .github: return "Github"
        default: return ""
        }
    }

    private func linkIconName(type: LinkType) -> String {
        switch type {
        case .website: return "globe_20"
        case .whitepaper: return "clipboard_20"
        case .reddit: return "reddit_20"
        case .twitter: return "twitter_20"
        case .telegram: return "telegram_20"
        case .github: return "github_20"
        default: return ""
        }
    }

    private func linkUrl(type: LinkType, url: String) -> String {
        switch type {
        case .website, .whitepaper, .reddit, .github: return url
        case .twitter:
            if url.hasPrefix("https://") {
                return url
            } else {
                return "https://twitter.com/\(url)"
            }
        case .telegram:
            if url.hasPrefix("https://") {
                return url
            } else {
                return "https://t.me/\(url)"
            }

        default: return ""
        }
    }

    private func links(info: MarketInfoOverview) -> [CoinOverviewViewModel.LinkViewItem] {
        let linkMap = info.links
        let linkTypes: [LinkType] = [.website, .whitepaper, .reddit, .twitter, .telegram, .github]

        return linkTypes.compactMap { linkType in
            guard let url = linkMap[linkType], !url.isEmpty else {
                return nil
            }

            return CoinOverviewViewModel.LinkViewItem(
                    title: linkTitle(type: linkType, url: url),
                    iconName: linkIconName(type: linkType),
                    url: linkUrl(type: linkType, url: url)
            )
        }
    }

}

extension CoinOverviewViewItemFactory {

    func viewItem(item: CoinOverviewService.Item, currency: Currency, fullCoin: FullCoin) -> CoinOverviewViewModel.ViewItem {
        let info = item.info
        let coinCode = fullCoin.coin.code
        let marketCapRank = info.marketCapRank.map { "#\($0)" }

        return CoinOverviewViewModel.ViewItem(
                coinViewItem: CoinOverviewViewModel.CoinViewItem(
                        name: fullCoin.coin.name,
                        marketCapRank: marketCapRank,
                        imageUrl: fullCoin.coin.imageUrl,
                        imagePlaceholderName: fullCoin.placeholderImageName
                ),

                marketCapRank: marketCapRank,
                marketCap: info.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
                totalSupply: roundedFormat(coinCode: coinCode, value: info.totalSupply),
                circulatingSupply: roundedFormat(coinCode: coinCode, value: info.circulatingSupply),
                volume24h: info.volume24h.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
                dilutedMarketCap: info.dilutedMarketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
                tvl: info.tvl.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
                genesisDate: info.genesisDate.map { DateHelper.instance.formatFullDateOnly(from: $0) },

                performance: performanceViewItems(info: info),
                categories: categories(info: info),
                contracts: contractViewItems(info: info),
                description: info.description,
                guideUrl: item.guideUrl,
                links: links(info: info)
        )
    }

}

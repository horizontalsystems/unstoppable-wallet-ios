import CurrencyKit
import Foundation
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
        case .day1: return "coin_overview.roi.hour24".localized
        case .week1: return "coin_overview.roi.day7".localized
        case .week2: return "coin_overview.roi.day14".localized
        case .month1: return "coin_overview.roi.day30".localized
        case .month6: return "coin_overview.roi.day200".localized
        case .year1: return "coin_overview.roi.year1".localized
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

    private func typesTitle(coinUid: String) -> String {
        switch coinUid {
        case "bitcoin", "litecoin": return "coin_overview.bips".localized
        case "bitcoin-cash": return "coin_overview.coin_types".localized
        default: return "coin_overview.blockchains".localized
        }
    }

    private func typeViewItems(tokenItems: [CoinOverviewService.TokenItem]) -> [CoinOverviewViewModel.TypeViewItem] {
        tokenItems.map { item in
            let blockchain = item.token.blockchain

            let title: String?
            let subtitle: String?
            var reference: String?
            var url: String?
            var showAdd = false
            var showAdded = false

            switch item.token.type {
            case .native:
                title = blockchain.name
                subtitle = "coin_platforms.native".localized
            case let .derived(derivation):
                title = derivation.mnemonicDerivation.title
                subtitle = derivation.mnemonicDerivation.addressType + derivation.mnemonicDerivation.recommended
            case let .addressType(type):
                title = type.bitcoinCashCoinType.title
                subtitle = type.bitcoinCashCoinType.description + type.bitcoinCashCoinType.recommended
            case let .eip20(address):
                title = blockchain.name
                subtitle = address.shortened
                reference = address
                url = blockchain.explorerUrl(reference: address)
            case let .bep2(symbol):
                title = blockchain.name
                subtitle = symbol
                reference = symbol
                url = blockchain.explorerUrl(reference: symbol)
            case let .spl(address):
                title = blockchain.name
                subtitle = address.shortened
                reference = address
                url = blockchain.explorerUrl(reference: address)
            case let .unsupported(_, _reference):
                title = blockchain.name
                subtitle = _reference?.shortened
                reference = _reference
                url = blockchain.explorerUrl(reference: reference)
            }

            switch item.state {
            case .canBeAdded: showAdd = true
            case .alreadyAdded: showAdded = true
            case .cannotBeAdded: ()
            }

            return CoinOverviewViewModel.TypeViewItem(
                iconUrl: blockchain.type.imageUrl,
                title: title,
                subtitle: subtitle,
                reference: reference,
                explorerUrl: url,
                showAdd: showAdd,
                showAdded: showAdded
            )
        }
    }

    private func linkTitle(type: LinkType, url: String) -> String {
        switch type {
        case .website:
            if let url = URL(string: url), let host = url.host {
                return host.stripping(prefix: "www.")
            } else {
                return "coin_overview.website".localized
            }
        case .whitepaper: return "coin_overview.whitepaper".localized
        case .reddit: return "Reddit"
        case .twitter: return url.stripping(prefix: "https://twitter.com/")
        case .telegram: return "Telegram"
        case .github: return "Github"
        default: return ""
        }
    }

    private func linkIconName(type: LinkType) -> String {
        switch type {
        case .website: return "globe_24"
        case .whitepaper: return "clipboard_24"
        case .reddit: return "reddit_24"
        case .twitter: return "twitter_24"
        case .telegram: return "telegram_24"
        case .github: return "github_24"
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
    func viewItem(item: CoinOverviewService.Item, currency: Currency, typesShown: Bool) -> CoinOverviewViewModel.ViewItem {
        let info = item.info
        let coin = info.fullCoin.coin
        let coinCode = coin.code
        let marketCapRank = info.marketCapRank.map { "#\($0)" }

        var types: CoinOverviewViewModel.TypesViewItem?

        if !item.tokens.isEmpty {
            types = CoinOverviewViewModel.TypesViewItem(
                title: typesTitle(coinUid: coin.uid),
                viewItems: typeViewItems(tokenItems: item.tokens.count > 4 && !typesShown ? Array(item.tokens.prefix(3)) : item.tokens),
                action: item.tokens.count > 4 ? (typesShown ? .showLess : .showMore) : nil
            )
        }

        return CoinOverviewViewModel.ViewItem(
            coinViewItem: CoinOverviewViewModel.CoinViewItem(
                name: coin.name,
                marketCapRank: marketCapRank,
                imageUrl: coin.imageUrl,
                imagePlaceholderName: "placeholder_circle_32"
            ),

            marketCapRank: marketCapRank,
            marketCap: info.marketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
            totalSupply: roundedFormat(coinCode: coinCode, value: info.totalSupply),
            circulatingSupply: roundedFormat(coinCode: coinCode, value: info.circulatingSupply),
            volume24h: info.volume24h.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
            dilutedMarketCap: info.dilutedMarketCap.flatMap { ValueFormatter.instance.formatShort(currency: currency, value: $0) },
            genesisDate: info.genesisDate.map { DateHelper.instance.formatFullDateOnly(from: $0) },

            performance: performanceViewItems(info: info),
            types: types,
            description: info.description,
            guideUrl: item.guideUrl,
            links: links(info: info)
        )
    }
}

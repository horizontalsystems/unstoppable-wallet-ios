import Foundation
import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import MarketKit
import UIKit

class CoinPageViewModel {
    private let service: CoinPageService
    private let returnOfInvestmentsViewItemsFactory = ReturnOfInvestmentsViewItemsFactory()
    private let marketViewItemFactory = MarketViewItemFactory()
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: CoinPageService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinMarketInfo>) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .completed(let info):
            let viewItem = ViewItem(
                    returnOfInvestmentsViewItems: returnOfInvestmentsViewItemsFactory.viewItems(info: info, diffCoinCodes: service.diffCoinCodes, timePeriods: CoinPageService.timePeriods),
                    tickers: info.tickers,
                    majorHoldersCoinType: majorHoldersCoinType,
                    fundCategories: info.meta.fundCategories,
                    categories: categories(info: info),
                    contractInfo: contractInfo(info: info),
                    guideUrl: service.guideUrl,
                    links: links(info: info),
                    marketInfo: marketInfo(marketCap: info.marketCap, marketCapRank: info.marketCapRank, dilutedMarketCap: info.dilutedMarketCap, volume24h: info.volume24h, tvlInfo: info.defiTvlInfo, genesisDate: info.genesisDate, circulatingSupply: info.circulatingSupply, totalSupply: info.totalSupply),
                    description: info.meta.description,
                    securities: securityViewItems(coinSecurity: info.meta.security),
                    auditsCoinType: auditsCoinType
            )
            stateRelay.accept(.loaded(viewItem: viewItem))
        case .failed:
            stateRelay.accept(.failed(error: "market.sync_error".localized))
        }
    }

    private func links(info: CoinMarketInfo) -> [Link] {
        let linkMap = info.meta.links
        let linkTypes: [LinkType] = [.website, .whitepaper, .reddit, .twitter, .telegram, .github]

        return linkTypes.compactMap { linkType in
            guard let url = linkMap[linkType], !url.isEmpty else {
                return nil
            }

            return Link(type: linkType, url: url)
        }
    }

    private func categories(info: CoinMarketInfo) -> [String]? {
        let categories = info.meta.categories
        return categories.isEmpty ? nil : categories
    }

    private func contractInfo(info: CoinMarketInfo) -> ContractInfo? {
        switch info.data.coinType {
        case .erc20(let address): return ContractInfo(title: "coin_page.contract".localized("ETH"), value: address)
        case .bep20(let address): return ContractInfo(title: "coin_page.contract".localized("BSC"), value: address)
        case .bep2(let symbol): return ContractInfo(title: "coin_page.bep2_symbol".localized, value: symbol)
        default: return nil
        }
    }

    private func marketInfo(marketCap: Decimal?, marketCapRank: Int?, dilutedMarketCap: Decimal?, volume24h: Decimal?, tvlInfo: DefiTvlInfo?, genesisDate: TimeInterval?, circulatingSupply: Decimal?, totalSupply: Decimal?) -> MarketInfo {
        marketViewItemFactory.viewItem(
                marketCap: marketCap,
                marketCapRank: marketCapRank,
                dilutedMarketCap: dilutedMarketCap,
                volume24h: volume24h,
                tvl: tvlInfo?.tvl,
                tvlRank: tvlInfo?.tvlRank,
                tvlRatio: tvlInfo?.tvlRatio,
                genesisDate: genesisDate,
                circulatingSupply: circulatingSupply,
                totalSupply: totalSupply,
                currency: service.currency,
                coinCode: service.coinCode
        )
    }

    private var majorHoldersCoinType: CoinType? {
        switch service.coinType {
        case .erc20: return service.coinType.coinType
        default: return nil
        }
    }

    private var auditsCoinType: CoinType? {
        switch service.coinType {
        case .erc20, .bep20: return service.coinType.coinType
        default: return nil
        }
    }

    private func securityViewItems(coinSecurity: CoinSecurity?) -> [SecurityViewItem] {
        guard let coinSecurity = coinSecurity else {
            return []
        }

        return [
            securityViewItem(type: .privacy, coinSecurity: coinSecurity),
            securityViewItem(type: .issuance, coinSecurity: coinSecurity),
            securityViewItem(type: .confiscationResistance, coinSecurity: coinSecurity),
            securityViewItem(type: .censorshipResistance, coinSecurity: coinSecurity)
        ]
    }

    private func securityViewItem(type: SecurityType, coinSecurity: CoinSecurity) -> SecurityViewItem {
        let value: String
        let color: UIColor

        switch type {
        case .privacy:
            let privacy: SecurityViewItemLevel
            switch coinSecurity.privacy {
            case .low: privacy = .low
            case .medium: privacy = .medium
            case .high: privacy = .high
            }

            value = privacy.title
            color = privacy.color
        case .issuance:
            let issuance: SecurityViewItemIssuance = coinSecurity.decentralized ? .decentralized : .centralized
            value = issuance.title
            color = issuance.color
        case .confiscationResistance:
            let resistance: SecurityViewItemResistance = coinSecurity.confiscationResistance ? .yes : .no
            value = resistance.title
            color = resistance.color
        case .censorshipResistance:
            let resistance: SecurityViewItemResistance = coinSecurity.censorshipResistance ? .yes : .no
            value = resistance.title
            color = resistance.color
        }

        return SecurityViewItem(type: type, value: value, valueColor: color)
    }

}

extension CoinPageViewModel {

    var coinType: CoinType {
        service.coinType.coinType
    }

    var title: String {
        service.coinCode
    }

    var subtitle: String {
        service.coinTitle
    }

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

    var coinTitle: String {
        service.coinTitle
    }

    var coinCode: String {
        service.coinCode
    }

    func securityInfoViewItems(type: SecurityType) -> [SecurityInfoViewItem] {
        switch type {
        case .privacy:
            return SecurityViewItemLevel.allCases.map { level in
                SecurityInfoViewItem(title: level.title, titleColor: level.color, text: "coin_page.security_parameters.privacy.description.\(level.rawValue)".localized)
            }
        case .issuance:
            return SecurityViewItemIssuance.allCases.map { issuance in
                SecurityInfoViewItem(title: issuance.title, titleColor: issuance.color, text: "coin_page.security_parameters.issuance.description.\(issuance.rawValue)".localized)
            }
        case .confiscationResistance:
            return SecurityViewItemResistance.allCases.map { resistance in
                SecurityInfoViewItem(title: resistance.title, titleColor: resistance.color, text: "coin_page.security_parameters.confiscation_resistance.description.\(resistance.rawValue)".localized)
            }
        case .censorshipResistance:
            return SecurityViewItemResistance.allCases.map { resistance in
                SecurityInfoViewItem(title: resistance.title, titleColor: resistance.color, text: "coin_page.security_parameters.censorship_resistance.description.\(resistance.rawValue)".localized)
            }
        }
    }

}

extension CoinPageViewModel {

    enum State {
        case loading
        case loaded(viewItem: ViewItem)
        case failed(error: String)
    }

    struct ViewItem {
        let returnOfInvestmentsViewItems: [[ReturnOfInvestmentsViewItem]]
        let tickers: [MarketTicker]
        let majorHoldersCoinType: CoinType?
        let fundCategories: [CoinFundCategory]
        let categories: [String]?
        let contractInfo: ContractInfo?
        let guideUrl: URL?
        let links: [Link]
        let marketInfo: MarketInfo
        let description: CoinMetaDescriptionType
        let securities: [SecurityViewItem]
        let auditsCoinType: CoinType?
    }

    struct SecurityViewItem {
        let type: SecurityType
        let value: String
        let valueColor: UIColor
    }

    struct SecurityInfoViewItem {
        let title: String
        let titleColor: UIColor
        let text: String
    }

    enum SecurityViewItemLevel: String, CaseIterable {
        case low
        case medium
        case high

        var title: String {
            "coin_page.security_parameters.level.\(rawValue)".localized
        }

        var color: UIColor {
            switch self {
            case .low: return .themeLucian
            case .medium: return .themeIssykBlue
            case .high: return .themeRemus
            }
        }
    }

    enum SecurityViewItemIssuance: String, CaseIterable {
        case decentralized
        case centralized

        var title: String {
            "coin_page.security_parameters.issuance.\(rawValue)".localized
        }

        var color: UIColor {
            switch self {
            case .decentralized: return .themeRemus
            case .centralized: return .themeLucian
            }
        }
    }

    enum SecurityViewItemResistance: String, CaseIterable {
        case yes
        case no

        var title: String {
            "coin_page.security_parameters.resistance.\(rawValue)".localized
        }

        var color: UIColor {
            switch self {
            case .yes: return .themeRemus
            case .no: return .themeLucian
            }
        }
    }

    enum SecurityType {
        case privacy
        case issuance
        case confiscationResistance
        case censorshipResistance

        var title: String {
            switch self {
            case .privacy: return "coin_page.security_parameters.privacy".localized
            case .issuance: return "coin_page.security_parameters.issuance".localized
            case .confiscationResistance: return "coin_page.security_parameters.confiscation_resistance".localized
            case .censorshipResistance: return "coin_page.security_parameters.censorship_resistance".localized
            }
        }
    }

    struct ContractInfo {
        let title: String
        let value: String
    }

    enum ReturnOfInvestmentsViewItem {
        case title(String)
        case subtitle(String)
        case content(String)
        case value(Decimal?)

        var font: UIFont? {
            switch self {
            case .title: return .subhead1
            case .subtitle: return .caption
            case .content: return .caption
            case .value: return nil
            }
        }

        var color: UIColor? {
            switch self {
            case .title: return .themeOz
            case .subtitle: return .themeBran
            case .content: return .themeGray
            case .value: return nil
            }
        }

    }

    struct Link {
        let type: LinkType
        let url: String

        var icon: UIImage? {
            switch type {
            case .website: return UIImage(named: "globe_20")
            case .whitepaper: return UIImage(named: "clipboard_20")
            case .reddit: return UIImage(named: "reddit_20")
            case .twitter: return UIImage(named: "twitter_20")
            case .telegram: return UIImage(named: "telegram_20")
            case .github: return UIImage(named: "github_20")
            default: return nil
            }
        }

        var title: String {
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
    }

    struct MarketInfo {
        public let marketCap: String?
        public let marketCapRank: String?
        public let volume24h: String?
        public let tvl: String?
        public let tvlRank: String?
        public let tvlRatio: String?
        public let genesisDate: String?
        public let circulatingSupply: String?
        public let totalSupply: String?
        public let dilutedMarketCap: String?
    }

}

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import UIKit

class CoinOverviewViewModel {
    private let service: CoinOverviewService
    private let performanceViewItemsFactory = PerformanceViewItemsFactory()
    private let marketViewItemFactory = CoinOverviewViewItemFactory()
    private let disposeBag = DisposeBag()

    private let stateRelay = BehaviorRelay<State>(value: .loading)

    init(service: CoinOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        sync(state: service.state)
    }

    private func sync(state: DataStatus<MarketInfoOverview>) {
        switch state {
        case .loading:
            stateRelay.accept(.loading)
        case .completed(let info):
            let marketInfo = marketViewItemFactory.viewItem(
                    marketCap: info.marketCap,
                    marketCapRank: info.marketCapRank,
                    dilutedMarketCap: info.dilutedMarketCap,
                    volume24h: info.volume24h,
                    tvl: info.tvl,
                    genesisDate: info.genesisDate?.timeIntervalSince1970,
                    circulatingSupply: info.circulatingSupply,
                    totalSupply: info.totalSupply,
                    currency: service.currency,
                    coinCode: service.fullCoin.coin.code
            )

            let viewItem = ViewItem(
                    performance: performanceViewItemsFactory.viewItems(info: info),
                    categories: categories(info: info),
                    contractInfo: contractInfo(),
                    guideUrl: service.guideUrl,
                    links: links(info: info),
                    marketInfo: marketInfo,
                    description: info.description,
                    imageUrl: service.fullCoin.coin.imageUrl,
                    imagePlaceholderName: service.fullCoin.placeholderImageName
            )
            stateRelay.accept(.loaded(viewItem: viewItem))
        case .failed:
            stateRelay.accept(.failed(error: "market.sync_error".localized))
        }
    }

    private func links(info: MarketInfoOverview) -> [Link] {
        let linkMap = info.links
        let linkTypes: [LinkType] = [.website, .whitepaper, .reddit, .twitter, .telegram, .github]

        return linkTypes.compactMap { linkType in
            guard let url = linkMap[linkType], !url.isEmpty else {
                return nil
            }

            return Link(type: linkType, url: url)
        }
    }

    private func categories(info: MarketInfoOverview) -> [String]? {
        let categories = info.categories
        return categories.isEmpty ? nil : categories.map { $0.name }
    }

    private func contractInfo() -> [ContractInfo]? {
        let contracts: [ContractInfo] = service.fullCoin.platforms.compactMap { platform in
            switch platform.coinType {
            case .erc20(let address): return ContractInfo(title: "coin_page.contract".localized("ETH"), value: address)
            case .bep20(let address): return ContractInfo(title: "coin_page.contract".localized("BSC"), value: address)
            case .bep2(let symbol): return ContractInfo(title: "coin_page.bep2_symbol".localized, value: symbol)
            default: return nil
            }
        }

        return contracts.isEmpty ? nil : contracts
    }

}

extension CoinOverviewViewModel {

    var coin: Coin {
        service.fullCoin.coin
    }

    func viewDidLoad() {
        service.fetchChartData()
    }

    var stateDriver: Driver<State> {
        stateRelay.asDriver()
    }

}

extension CoinOverviewViewModel {

    enum State {
        case loading
        case loaded(viewItem: ViewItem)
        case failed(error: String)
    }

    struct ViewItem {
        let performance: [[PerformanceViewItem]]
        let categories: [String]?
        let contractInfo: [ContractInfo]?
        let guideUrl: URL?
        let links: [Link]
        let marketInfo: MarketInfo
        let description: String
        let imageUrl: String
        let imagePlaceholderName: String
    }

    struct ContractInfo {
        let title: String
        let value: String
    }

    enum PerformanceViewItem {
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
        public let genesisDate: String?
        public let circulatingSupply: String?
        public let totalSupply: String?
        public let dilutedMarketCap: String?
    }

}

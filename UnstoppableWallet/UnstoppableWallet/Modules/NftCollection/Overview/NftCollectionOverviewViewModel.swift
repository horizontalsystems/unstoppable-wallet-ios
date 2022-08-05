import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MarketKit
import Chart
import CurrencyKit

class NftCollectionOverviewViewModel {
    private let service: NftCollectionOverviewService
    private let coinService: CoinService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    init(service: NftCollectionOverviewService, coinService: CoinService) {
        self.service = service
        self.coinService = coinService

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<NftCollectionOverviewService.Item>) {
        switch state {
        case .loading:
            viewItemRelay.accept(nil)
            loadingRelay.accept(true)
            syncErrorRelay.accept(false)
        case .completed(let item):
            viewItemRelay.accept(viewItem(item: item))
            loadingRelay.accept(false)
            syncErrorRelay.accept(false)
        case .failed:
            viewItemRelay.accept(nil)
            loadingRelay.accept(false)
            syncErrorRelay.accept(true)
        }
    }

    private func viewItem(item: NftCollectionOverviewService.Item) -> ViewItem {
        let collection = item.collection

        return ViewItem(
                logoImageUrl: collection.imageUrl,
                name: collection.name,
                description: collection.description,
                contracts: collection.contracts.map { contractViewItem(contract: $0) },
                links: linkViewItems(collection: collection),
                statCharts: statViewItem(item: item)
        )
    }

    private func contractViewItem(contract: NftCollection.Contract) -> ContractViewItem {
        ContractViewItem(
                iconUrl: BlockchainType.ethereum.imageUrl,
                reference: contract.address,
                explorerUrl: "https://etherscan.io/token/\(contract.address)"
        )
    }

    private func linkViewItems(collection: NftCollection) -> [LinkViewItem] {
        var viewItems = [LinkViewItem]()

        if let url = collection.externalUrl {
            viewItems.append(LinkViewItem(type: .website, url: url))
        }

        viewItems.append(LinkViewItem(type: .openSea, url: "https://opensea.io/collection/\(collection.uid)"))

        if let url = collection.discordUrl {
            viewItems.append(LinkViewItem(type: .discord, url: url))
        }
        if let username = collection.twitterUsername {
            viewItems.append(LinkViewItem(type: .twitter, url: "https://twitter.com/\(username)"))
        }

        return viewItems
    }

    private func statPricePointViewItem(title: String, pricePoints: [NftCollectionStatCharts.PricePoint]?) -> NftChartMarketCardView.ViewItem? {
        guard let points = pricePoints,
              points.count > 1,
              let first = points.first,
              let last = points.last else {
            return nil
        }

        let chartItems = points.map {
            ChartItem(timestamp: $0.timestamp).added(name: .rate, value: $0.value)
        }
        let chartData = ChartData(items: chartItems, startTimestamp: first.timestamp, endTimestamp: last.timestamp)

        let diffValue = (last.value / first.value - 1) * 100
        let diff = DiffLabel.formatted(value: diffValue)
        let diffColor = DiffLabel.color(value: diffValue)

        let value: String? = first.token.flatMap {
            let coinValue = CoinValue(kind: .token(token: $0), value: last.value)
            return ValueFormatter.instance.formatShort(coinValue: coinValue)
        }

        let additional = coinService.rate.map { ValueFormatter.instance.formatShort(currency: $0.currency, value: $0.value * last.value) }

        return NftChartMarketCardView.ViewItem(
                title: title,
                value: value,
                additionalValue: additional ?? "---".localized,
                diff: diff ?? "n/a".localized,
                diffColor: diffColor,
                data: chartData,
                trend: diffValue.isSignMinus ? .down : .up
        )
    }

    private func statPointViewItem(title: String, points: [NftCollectionStatCharts.Point]?, averagePrice: NftPrice?) -> NftChartMarketCardView.ViewItem? {
        guard let points = points,
              points.count > 1,
              let first = points.first,
              let last = points.last else {
            return nil
        }

        let chartItems = points.map {
            ChartItem(timestamp: $0.timestamp).added(name: .rate, value: $0.value)
        }
        let chartData = ChartData(items: chartItems, startTimestamp: first.timestamp, endTimestamp: last.timestamp)

        let diffValue = (last.value / first.value - 1) * 100
        let diff = DiffLabel.formatted(value: diffValue)
        let diffColor = DiffLabel.color(value: diffValue)

        let value = ValueFormatter.instance.formatShort(value: last.value, decimalCount: 0, symbol: "NFT")

        let averageValue: String? = averagePrice.flatMap {
            let coinValue = CoinValue(kind: .token(token: $0.token), value: $0.value)
            return ValueFormatter.instance.formatShort(coinValue: coinValue)
        }
        let additional = averageValue.map { "~\($0) / NFT" }

        return NftChartMarketCardView.ViewItem(
                title: title,
                value: value,
                additionalValue: additional ?? "----".localized,
                diff: diff ?? "n/a".localized,
                diffColor: diffColor,
                data: chartData,
                trend: diffValue.isSignMinus ? .down : .up
        )
    }

    private func statViewItem(item: NftCollectionOverviewService.Item) -> StatChartViewItem {
        StatChartViewItem(
                ownerCount: item.collection.stats.ownerCount.flatMap { ValueFormatter.instance.formatShort(value: Decimal($0)) },
                itemCount: item.collection.stats.count.flatMap { ValueFormatter.instance.formatShort(value: Decimal($0)) },
                oneDayVolumeItems: statPricePointViewItem(title: "nft_collection.overview.24h_volume".localized, pricePoints: item.collection.statCharts?.oneDayVolumePoints),
                averagePriceItems: statPricePointViewItem(title: "nft_collection.overview.all_time_average".localized, pricePoints: item.collection.statCharts?.averagePricePoints),
                floorPriceItems: statPricePointViewItem(title: "nft_collection.overview.floor_price".localized, pricePoints: item.collection.statCharts?.floorPricePoints),
                oneDaySalesItems: statPointViewItem(title: "nft_collection.overview.today_sellers".localized, points: item.collection.statCharts?.oneDaySalesPoints, averagePrice: item.collection.stats.averagePrice1d)
        )
    }

}

extension NftCollectionOverviewViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    func onTapRetry() {
        service.resync()
    }

}

extension NftCollectionOverviewViewModel {

    struct ViewItem {
        let logoImageUrl: String?
        let name: String
        let description: String?
        let contracts: [ContractViewItem]
        let links: [LinkViewItem]
        let statCharts: StatChartViewItem
    }

    struct ContractViewItem {
        let iconUrl: String
        let reference: String
        let explorerUrl: String
    }

    struct LinkViewItem {
        let type: LinkType
        let url: String
    }

    struct StatChartViewItem {
        let ownerCount: String?
        let itemCount: String?
        let oneDayVolumeItems: ChartMarketCardView.ViewItem?
        let averagePriceItems: ChartMarketCardView.ViewItem?
        let floorPriceItems: ChartMarketCardView.ViewItem?
        let oneDaySalesItems: ChartMarketCardView.ViewItem?
    }

    enum LinkType {
        case website
        case openSea
        case discord
        case twitter
    }

}

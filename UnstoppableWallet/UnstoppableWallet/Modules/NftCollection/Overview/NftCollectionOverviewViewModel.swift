import Chart
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

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
        case let .completed(item):
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
            logoImageUrl: collection.imageUrl ?? collection.thumbnailImageUrl,
            name: collection.name,
            description: collection.description,
            contracts: collection.contracts.map { contractViewItem(contract: $0) },
            links: linkViewItems(collection: collection),
            statsViewItems: statViewItem(collection: collection),
            royalty: collection.royalty.flatMap { ValueFormatter.instance.format(percentValue: $0, signType: .never) },
            inceptionDate: collection.inceptionDate.map { DateFormatter.cachedFormatter(format: "MMMM d, yyyy").string(from: $0) }
        )
    }

    private func contractViewItem(contract: NftContractMetadata) -> ContractViewItem {
        ContractViewItem(
            iconUrl: service.blockchainType.imageUrl,
            name: contract.name,
            schema: contract.schema,
            reference: contract.address,
            explorerUrl: service.blockchain?.explorerUrl(reference: contract.address)
        )
    }

    private func linkViewItems(collection: NftCollectionMetadata) -> [LinkViewItem] {
        var viewItems = [LinkViewItem]()

        if let url = collection.externalLink {
            viewItems.append(LinkViewItem(type: .website, url: url))
        }

//        if let providerLink = service.providerLink {
//            viewItems.append(LinkViewItem(type: .provider(title: providerLink.title), url: providerLink.url))
//        }

        if let url = collection.discordLink {
            viewItems.append(LinkViewItem(type: .discord, url: url))
        }
        if let username = collection.twitterUsername {
            viewItems.append(LinkViewItem(type: .twitter, url: "https://twitter.com/\(username)"))
        }

        return viewItems
    }

    private func statViewItem(collection: NftCollectionMetadata) -> StatsViewItem {
        let ownerCount = [
            collection.ownerCount.flatMap { ValueFormatter.instance.formatShort(value: Decimal($0)) },
            "nft_collection.overview.owners".localized,
        ].compactMap { $0 }
            .joined(separator: " ")

        let ownerViewItem = MarketCardView.ViewItem(
            title: "nft_collection.overview.items".localized,
            value: collection.count.flatMap { ValueFormatter.instance.formatShort(value: Decimal($0)) },
            description: ownerCount
        )

        let floorPriceViewItem = collection.floorPrice.map { floorPrice -> MarketCardView.ViewItem in
            let floorPriceInCurrency = coinService.rate
                .map {
                    ValueFormatter.instance
                        .formatShort(currency: $0.currency, value: $0.value * floorPrice.value)
                } ?? "n/a".localized

            return MarketCardView.ViewItem(
                title: "nft_collection.overview.floor_price".localized,
                value: string(nftPrice: floorPrice),
                description: floorPriceInCurrency
            )
        } ?? MarketCardView.ViewItem(
            title: "nft_collection.overview.floor_price".localized,
            value: "---",
            description: "n/a".localized
        )

        let volumeDiff = collection.change1d
            .flatMap { DiffLabel.formatted(value: $0) }
        let volumeColor = collection.change1d
            .map { DiffLabel.color(value: $0) }

        let volume24ViewItem = collection.volume1d.map { volume1d in
            MarketCardView.ViewItem(
                title: "nft_collection.overview.24h_volume".localized,
                value: string(nftPrice: volume1d),
                description: volumeDiff,
                descriptionColor: volumeColor
            )
        }

        let averageValue: String? = collection.averagePrice1d.flatMap {
            let appValue = AppValue(token: $0.token, value: $0.value)
            return appValue.formattedShort()
        }
        let additional = averageValue.map { "~\($0) per NFT" }

        let todaySellersViewItem = collection.sales1d.map { sales1d in
            MarketCardView.ViewItem(
                title: "nft_collection.overview.today_sellers".localized,
                value: "\(sales1d) NFT",
                description: additional
            )
        }

        return StatsViewItem(
            countItems: ownerViewItem,
            oneDayVolumeItems: volume24ViewItem,
            floorPriceItems: floorPriceViewItem,
            oneDaySalesItems: todaySellersViewItem
        )
    }

    private func string(nftPrice: NftPrice?) -> String? {
        guard let price = nftPrice else {
            return nil
        }

        let appValue = AppValue(token: price.token, value: price.value)
        return appValue.formattedShort()
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
        let statsViewItems: StatsViewItem
        let royalty: String?
        let inceptionDate: String?
    }

    struct ContractViewItem {
        let iconUrl: String
        let name: String
        let schema: String?
        let reference: String
        let explorerUrl: String?
    }

    struct LinkViewItem {
        let type: LinkType
        let url: String
    }

    struct StatsViewItem {
        let countItems: MarketCardView.ViewItem?
        let oneDayVolumeItems: MarketCardView.ViewItem?
        let floorPriceItems: MarketCardView.ViewItem?
        let oneDaySalesItems: MarketCardView.ViewItem?
    }

    enum LinkType {
        case website
        case provider(title: String)
        case discord
        case twitter
    }
}

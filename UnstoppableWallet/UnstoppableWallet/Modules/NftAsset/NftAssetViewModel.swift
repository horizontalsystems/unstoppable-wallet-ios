import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class NftAssetViewModel {
    private let service: NftAssetService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let statsViewItemRelay = BehaviorRelay<StatsViewItem?>(value: nil)

    init(service: NftAssetService) {
        self.service = service

        subscribe(disposeBag, service.statsItemObservable) { [weak self] in self?.sync(statsItem: $0) }

        syncState()
        sync(statsItem: service.statsItem)
    }

    private func syncState() {
        let asset = service.asset
        let collection = service.collection

        let viewItem = ViewItem(
                imageUrl: asset.imageUrl,
                name: asset.name ?? "#\(asset.tokenId)",
                collectionName: collection.name,
                traits: asset.traits.map { traitViewItem(trait: $0, totalSupply: collection.totalSupply) },
                description: asset.description,
                contractAddress: asset.contract.address,
                tokenId: asset.tokenId,
                schemaName: asset.contract.schemaName,
                blockchain: "Ethereum",
                links: linkViewItems(collection: collection, asset: asset)
        )

        viewItemRelay.accept(viewItem)
    }

    private func sync(statsItem: NftAssetService.StatsItem) {
        let viewItem = StatsViewItem(
                lastSale: priceViewItem(priceItem: statsItem.lastSale),
                average7d: priceViewItem(priceItem: statsItem.average7d),
                average30d: priceViewItem(priceItem: statsItem.average30d),
                collectionFloor: priceViewItem(priceItem: statsItem.collectionFloor),
                bestOffer: priceViewItem(priceItem: statsItem.bestOffer),
                sale: saleViewItem(saleItem: statsItem.sale)
        )

        statsViewItemRelay.accept(viewItem)
    }

    private func saleViewItem(saleItem: NftAssetService.SaleItem?) -> SaleViewItem? {
        guard let saleItem = saleItem else {
            return nil
        }

        return SaleViewItem(
                untilDate: "nft_asset.until_date".localized(DateHelper.instance.formatFullTime(from: saleItem.untilDate)),
                type: saleItem.type,
                price: PriceViewItem(
                        coinValue: coinValue(priceItem: saleItem.price),
                        fiatValue: fiatValue(priceItem: saleItem.price)
                )
        )
    }

    private func priceViewItem(priceItem: NftAssetService.PriceItem?) -> PriceViewItem? {
        guard let priceItem = priceItem else {
            return nil
        }

        return PriceViewItem(
                coinValue: coinValue(priceItem: priceItem),
                fiatValue: fiatValue(priceItem: priceItem)
        )
    }

    private func coinValue(priceItem: NftAssetService.PriceItem) -> String {
        let price = priceItem.nftPrice
        let coinValue = CoinValue(kind: .platformCoin(platformCoin: price.platformCoin), value: price.value)
        return ValueFormatter.instance.format(coinValue: coinValue, fractionPolicy: .threshold(high: 0.01, low: 0)) ?? "---"
    }

    private func fiatValue(priceItem: NftAssetService.PriceItem) -> String {
        guard let coinPrice = priceItem.coinPrice else {
            return "---"
        }

        let currencyValue = CurrencyValue(currency: coinPrice.price.currency, value: priceItem.nftPrice.value * coinPrice.price.value)
        return ValueFormatter.instance.format(currencyValue: currencyValue, fractionPolicy: .threshold(high: 1000, low: 0.01)) ?? "---"
    }

    private func traitViewItem(trait: NftAsset.Trait, totalSupply: Int) -> TraitViewItem {
        TraitViewItem(
                type: trait.type.capitalized,
                value: trait.value.capitalized,
                percent: trait.count == 0 || totalSupply == 0 ? nil : "\(trait.count * 100 / totalSupply)%"
        )
    }

    private func linkViewItems(collection: NftCollection, asset: NftAsset) -> [LinkViewItem] {
        var viewItems = [LinkViewItem]()

        if let url = asset.externalLink {
            viewItems.append(LinkViewItem(type: .website, url: url))
        }
        if let url = asset.permalink {
            viewItems.append(LinkViewItem(type: .openSea, url: url))
        }
        if let url = collection.discordUrl {
            viewItems.append(LinkViewItem(type: .discord, url: url))
        }
        if let username = collection.twitterUsername {
            viewItems.append(LinkViewItem(type: .twitter, url: "https://twitter.com/\(username)"))
        }

        return viewItems
    }

}

extension NftAssetViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

    var statsViewItemDriver: Driver<StatsViewItem?> {
        statsViewItemRelay.asDriver()
    }

}

extension NftAssetViewModel {

    struct ViewItem {
        let imageUrl: String?
        let name: String
        let collectionName: String
        let traits: [TraitViewItem]
        let description: String?
        let contractAddress: String
        let tokenId: String
        let schemaName: String
        let blockchain: String
        let links: [LinkViewItem]
    }

    struct StatsViewItem {
        let lastSale: PriceViewItem?
        let average7d: PriceViewItem?
        let average30d: PriceViewItem?
        let collectionFloor: PriceViewItem?
        let bestOffer: PriceViewItem?
        let sale: SaleViewItem?
    }

    struct SaleViewItem {
        let untilDate: String
        let type: NftAssetService.SalePriceType
        let price: PriceViewItem
    }

    struct PriceViewItem {
        let coinValue: String
        let fiatValue: String
    }

    struct TraitViewItem {
        let type: String
        let value: String
        let percent: String?
    }

    struct LinkViewItem {
        let type: LinkType
        let url: String
    }

    enum LinkType {
        case website
        case openSea
        case discord
        case twitter
    }

}

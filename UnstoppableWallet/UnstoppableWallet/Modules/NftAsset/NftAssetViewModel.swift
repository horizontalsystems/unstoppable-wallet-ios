import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class NftAssetViewModel {
    private let service: NftAssetService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let statsViewItemRelay = BehaviorRelay<StatsViewItem?>(value: nil)
    private let openTraitRelay = PublishRelay<String>()

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
                traits: asset.traits.enumerated().map { traitViewItem(index: $0, trait: $1, totalSupply: collection.totalSupply) },
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
                        coinValue: saleItem.price.map { coinValue(priceItem: $0) } ?? "---",
                        fiatValue: saleItem.price.map { fiatValue(priceItem: $0) } ?? "---"
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

    private func traitViewItem(index: Int, trait: NftAsset.Trait, totalSupply: Int) -> TraitViewItem {
        var percentString: String?

        if trait.count != 0 && totalSupply != 0 {
            let percent = Double(trait.count) * 100.0 / Double(totalSupply)
            let rounded: Double

            if percent >= 10 {
                rounded = round(percent)
            } else if percent >= 1 {
                rounded = Double(round(percent * 10) / 10)
            } else {
                rounded = Double(round(percent * 100) / 100)
            }

            percentString = String(format: "%g", rounded)
        }

        return TraitViewItem(
                index: index,
                type: trait.type.capitalized,
                value: trait.value.capitalized,
                percent: percentString.map { "\($0)%" }
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

    var openTraitSignal: Signal<String> {
        openTraitRelay.asSignal()
    }

    func onSelectTrait(index: Int) {
        guard index < service.asset.traits.count else {
            return
        }

        let trait = service.asset.traits[index]

        guard let traitName = trait.type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let traitValue = trait.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }

        let slug = service.collection.uid

        let url = "https://opensea.io/assets/\(slug)?search[stringTraits][0][name]=\(traitName)&search[stringTraits][0][values][0]=\(traitValue)&search[sortAscending]=true&search[sortBy]=PRICE"
        openTraitRelay.accept(url)
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
        let index: Int
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

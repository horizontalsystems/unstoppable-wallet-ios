import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class NftAssetViewModel {
    private let service: NftAssetService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    private let openTraitRelay = PublishRelay<String>()

    init(service: NftAssetService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<NftAssetService.Item>) {
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

    private func viewItem(item: NftAssetService.Item) -> ViewItem {
        let asset = item.asset
        let collection = item.collection

        return ViewItem(
                imageUrl: asset.imageUrl,
                name: asset.name ?? "#\(asset.tokenId)",
                collectionUid: collection.uid,
                collectionName: collection.name,
                lastSale: priceViewItem(priceItem: item.lastSale),
                average7d: priceViewItem(priceItem: item.average7d),
                average30d: priceViewItem(priceItem: item.average30d),
                collectionFloor: priceViewItem(priceItem: item.collectionFloor),
                bestOffer: priceViewItem(priceItem: item.bestOffer),
                sale: saleViewItem(saleItem: item.sale),
                traits: asset.traits.enumerated().map { traitViewItem(index: $0, trait: $1, totalSupply: collection.stats.totalSupply) },
                description: asset.description,
                contractAddress: asset.contract.address,
                tokenId: asset.tokenId,
                schemaName: asset.contract.schemaName,
                blockchain: "Ethereum",
                links: linkViewItems(collection: collection, asset: asset)
        )
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
        let coinValue = CoinValue(kind: .token(token: price.token), value: price.value)
        return ValueFormatter.instance.formatShort(coinValue: coinValue) ?? "---"
    }

    private func fiatValue(priceItem: NftAssetService.PriceItem) -> String {
        guard let coinPrice = priceItem.coinPrice else {
            return "---"
        }

        return ValueFormatter.instance.formatShort(currency: coinPrice.price.currency, value: priceItem.nftPrice.value * coinPrice.price.value) ?? "---"
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

    var loadingDriver: Driver<Bool> {
        loadingRelay.asDriver()
    }

    var syncErrorDriver: Driver<Bool> {
        syncErrorRelay.asDriver()
    }

    var openTraitSignal: Signal<String> {
        openTraitRelay.asSignal()
    }

    func onTapRetry() {
        service.resync()
    }

    func onSelectTrait(index: Int) {
        guard case .completed(let item) = service.state else {
            return
        }

        guard index < item.asset.traits.count else {
            return
        }

        let trait = item.asset.traits[index]

        guard let traitName = trait.type.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let traitValue = trait.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return
        }

        let slug = item.collection.uid

        let url = "https://opensea.io/assets/\(slug)?search[stringTraits][0][name]=\(traitName)&search[stringTraits][0][values][0]=\(traitValue)&search[sortAscending]=true&search[sortBy]=PRICE"
        openTraitRelay.accept(url)
    }

}

extension NftAssetViewModel {

    struct ViewItem {
        let imageUrl: String?
        let name: String
        let collectionUid: String
        let collectionName: String
        let lastSale: PriceViewItem?
        let average7d: PriceViewItem?
        let average30d: PriceViewItem?
        let collectionFloor: PriceViewItem?
        let bestOffer: PriceViewItem?
        let sale: SaleViewItem?
        let traits: [TraitViewItem]
        let description: String?
        let contractAddress: String
        let tokenId: String
        let schemaName: String
        let blockchain: String
        let links: [LinkViewItem]
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

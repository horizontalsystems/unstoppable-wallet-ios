import Foundation
import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit
import MarketKit

class NftAssetOverviewViewModel {
    private let service: NftAssetOverviewService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)
    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let syncErrorRelay = BehaviorRelay<Bool>(value: false)

    private let openTraitRelay = PublishRelay<String>()

    init(service: NftAssetOverviewService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<NftAssetOverviewService.Item>) {
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

    private func viewItem(item: NftAssetOverviewService.Item) -> ViewItem {
        let asset = item.asset
        let collection = item.collection

        return ViewItem(
                nftImage: item.assetNftImage,
                name: asset.name ?? "#\(service.nftUid.tokenId)",
                providerCollectionUid: asset.providerCollectionUid,
                collectionName: collection.name,
                lastSale: priceViewItem(priceItem: item.lastSale),
                average7d: priceViewItem(priceItem: item.average7d),
                average30d: priceViewItem(priceItem: item.average30d),
                collectionFloor: priceViewItem(priceItem: item.collectionFloor),
                bestOffer: priceViewItem(priceItem: item.bestOffer),
                sale: saleViewItem(saleItem: item.sale),
                traits: asset.traits.enumerated().map { traitViewItem(index: $0, trait: $1, totalSupply: collection.totalSupply) },
                description: asset.description,
                contractAddress: service.nftUid.contractAddress,
                tokenId: service.nftUid.tokenId,
                schemaName: asset.nftType,
                blockchain: service.nftUid.blockchainType.uid,
                links: linkViewItems(asset: asset, collection: collection),
                sendVisible: item.isOwned
        )
    }

    private func saleViewItem(saleItem: NftAssetOverviewService.SaleItem?) -> SaleViewItem? {
        guard let saleItem = saleItem, let listing = saleItem.bestListing else {
            return nil
        }

        return SaleViewItem(
                untilDate: "nft_asset.until_date".localized(DateHelper.instance.formatFullTime(from: listing.untilDate)),
                type: saleItem.type,
                price: PriceViewItem(
                        coinValue: coinValue(priceItem: listing.price),
                        fiatValue: fiatValue(priceItem: listing.price)
                )
        )
    }

    private func priceViewItem(priceItem: NftAssetOverviewService.PriceItem?) -> PriceViewItem? {
        guard let priceItem = priceItem else {
            return nil
        }

        return PriceViewItem(
                coinValue: coinValue(priceItem: priceItem),
                fiatValue: fiatValue(priceItem: priceItem)
        )
    }

    private func coinValue(priceItem: NftAssetOverviewService.PriceItem) -> String {
        let price = priceItem.nftPrice
        let coinValue = CoinValue(kind: .token(token: price.token), value: price.value)
        return ValueFormatter.instance.formatShort(coinValue: coinValue) ?? "---"
    }

    private func fiatValue(priceItem: NftAssetOverviewService.PriceItem) -> String {
        guard let coinPrice = priceItem.coinPrice else {
            return "---"
        }

        return ValueFormatter.instance.formatShort(currency: coinPrice.price.currency, value: priceItem.nftPrice.value * coinPrice.price.value) ?? "---"
    }

    private func traitViewItem(index: Int, trait: NftAssetMetadata.Trait, totalSupply: Int?) -> TraitViewItem {
        var percentString: String?

        if let totalSupply = totalSupply, trait.count != 0, totalSupply != 0 {
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

    private func linkViewItems(asset: NftAssetMetadata, collection: NftCollectionMetadata) -> [LinkViewItem] {
        var viewItems = [LinkViewItem]()

        if let url = asset.externalLink {
            viewItems.append(LinkViewItem(type: .website, url: url))
        }
        if let title = service.providerTitle, let link = asset.providerLink {
            viewItems.append(LinkViewItem(type: .provider(title: title), url: link))
        }
        if let url = collection.discordLink {
            viewItems.append(LinkViewItem(type: .discord, url: url))
        }
        if let username = collection.twitterUsername {
            viewItems.append(LinkViewItem(type: .twitter, url: "https://twitter.com/\(username)"))
        }

        return viewItems
    }

}

extension NftAssetOverviewViewModel {
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

    var nftUid: NftUid {
        service.nftUid
    }

    var blockchainType: BlockchainType {
        service.nftUid.blockchainType
    }

    var providerTitle: String? {
        service.providerTitle
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

        guard let providerTraitLink = item.asset.providerTraitLink else {
            return
        }

        let url = providerTraitLink
                .replacingOccurrences(of: "$traitName", with: traitName)
                .replacingOccurrences(of: "$traitValue", with: traitValue)

        openTraitRelay.accept(url)
    }

}

extension NftAssetOverviewViewModel {

    struct ViewItem {
        let nftImage: NftImage?
        let name: String
        let providerCollectionUid: String
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
        let sendVisible: Bool
    }

    struct SaleViewItem {
        let untilDate: String
        let type: NftAssetMetadata.SaleType
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
        case provider(title: String)
        case discord
        case twitter
    }

}

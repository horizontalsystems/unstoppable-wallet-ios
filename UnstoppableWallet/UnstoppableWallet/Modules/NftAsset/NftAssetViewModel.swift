import RxSwift
import RxRelay
import RxCocoa
import CurrencyKit

class NftAssetViewModel {
    private let service: NftAssetService
    private let disposeBag = DisposeBag()

    private let viewItemRelay = BehaviorRelay<ViewItem?>(value: nil)

    init(service: NftAssetService) {
        self.service = service

        syncState()
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

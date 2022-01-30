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
                name: asset.name ?? "#\(asset.tokenId)",
                collectionName: collection.name,
                traits: asset.traits.map { traitViewItem(trait: $0, totalSupply: collection.totalSupply) },
                description: asset.description
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

}

extension NftAssetViewModel {

    var viewItemDriver: Driver<ViewItem?> {
        viewItemRelay.asDriver()
    }

}

extension NftAssetViewModel {

    struct ViewItem {
        let name: String
        let collectionName: String
        let traits: [TraitViewItem]
        let description: String?
    }

    struct TraitViewItem {
        let type: String
        let value: String
        let percent: String?
    }

}

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
                name: asset.name ?? "\(collection.name) #\(asset.tokenId)",
                collectionName: collection.name
        )

        viewItemRelay.accept(viewItem)
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
    }

}

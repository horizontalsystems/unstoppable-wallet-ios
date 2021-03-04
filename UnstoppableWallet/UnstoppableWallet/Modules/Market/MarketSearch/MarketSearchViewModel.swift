import Foundation
import RxSwift
import RxCocoa
import CoinKit

class MarketSearchViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketSearchService

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])

    init(service: MarketSearchService) {
        self.service = service

        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.sync(items: $0) }
    }

    private func sync(items: [MarketSearchService.Item]) {
        let viewItems = items.map { item -> ViewItem in
            ViewItem(coinTitle: item.coinTitle, coinCode: item.coinCode, blockchainType: item.coinType.blockchainType)
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension MarketSearchViewModel {

    public var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    func apply(filter: String?) {
        service.filter = filter
    }

}

extension MarketSearchViewModel {

    struct ViewItem {
        let coinTitle: String
        let coinCode: String
        let blockchainType: String?
    }

}

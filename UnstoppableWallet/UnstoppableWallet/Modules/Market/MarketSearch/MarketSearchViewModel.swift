import Foundation
import RxSwift
import RxCocoa
import CoinKit

class MarketSearchViewModel {
    private let disposeBag = DisposeBag()
    private let service: MarketSearchService

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let emptyResultRelay = BehaviorRelay<Bool>(value: false)
    private let showAdvancedSearchRelay = BehaviorRelay<Bool>(value: true)

    init(service: MarketSearchService) {
        self.service = service

        subscribe(disposeBag, service.itemUpdatedObservable) { [weak self] in self?.sync(items: $0) }
    }

    private func sync(items: [MarketSearchService.Item]?) {
        showAdvancedSearchRelay.accept(service.filter?.isEmpty ?? true)
        emptyResultRelay.accept(items?.isEmpty ?? false)

        guard let items = items else {
            viewItemsRelay.accept([])
            return
        }

        let viewItems = items.map { item -> ViewItem in
            ViewItem(coinTitle: item.coinTitle, coinCode: item.coinCode, coinType: item.coinType, blockchainType: item.coinType.blockchainType)
        }

        viewItemsRelay.accept(viewItems)
    }

}

extension MarketSearchViewModel {

    var viewItemsDriver: Driver<[ViewItem]> {
        viewItemsRelay.asDriver()
    }

    var emptyResultDriver: Driver<Bool> {
        emptyResultRelay.asDriver()
    }

    var showAdvancedSearchDriver: Driver<Bool> {
        showAdvancedSearchRelay.asDriver()
    }

    func apply(filter: String?) {
        service.filter = filter?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

extension MarketSearchViewModel {

    struct ViewItem {
        let coinTitle: String
        let coinCode: String
        let coinType: CoinType
        let blockchainType: String?
    }

}

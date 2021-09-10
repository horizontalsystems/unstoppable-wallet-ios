import Foundation
import RxSwift
import RxCocoa
import MarketKit

class MarketSearchViewModel {
    private let service: MarketSearchService
    private let disposeBag = DisposeBag()

    private let viewItemsRelay = BehaviorRelay<[ViewItem]>(value: [])
    private let emptyResultRelay = BehaviorRelay<Bool>(value: false)
    private let showAdvancedSearchRelay = BehaviorRelay<Bool>(value: true)

    init(service: MarketSearchService) {
        self.service = service

        subscribe(disposeBag, service.coinsUpdatedObservable) { [weak self] in self?.sync(coins: $0) }
    }

    private func sync(coins: [Coin]) {
        showAdvancedSearchRelay.accept(service.filter.isEmpty)
        emptyResultRelay.accept(coins.isEmpty && !service.filter.isEmpty)

        let viewItems = coins.map { coin -> ViewItem in
            ViewItem(
                    coinIconUrlString: coin.imageUrl,
                    coinName: coin.name,
                    coinCode: coin.code
            )
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
        service.filter = filter?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

}

extension MarketSearchViewModel {

    struct ViewItem {
        let coinIconUrlString: String
        let coinName: String
        let coinCode: String
    }

}

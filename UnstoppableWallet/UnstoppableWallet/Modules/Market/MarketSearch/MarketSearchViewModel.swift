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

        subscribe(disposeBag, service.coinsUpdatedObservable) { [weak self] in self?.sync(fullCoins: $0) }
    }

    private func sync(fullCoins: [FullCoin]) {
        showAdvancedSearchRelay.accept(service.filter.isEmpty)
        emptyResultRelay.accept(fullCoins.isEmpty && !service.filter.isEmpty)

        let viewItems = fullCoins.map { fullCoin -> ViewItem in
            ViewItem(
                    coinIconUrlString: fullCoin.coin.imageUrl,
                    coinIconPlaceholderName: fullCoin.placeholderImageName,
                    coinName: fullCoin.coin.name,
                    coinCode: fullCoin.coin.code
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
        let coinIconPlaceholderName: String
        let coinName: String
        let coinCode: String
    }

}

import CurrencyKit
import RxSwift
import RxRelay
import RxCocoa

class MarketDiscoveryViewModel {
    private let service: MarketDiscoveryService
    private let disposeBag = DisposeBag()

    private let selectedFilterIndexRelay = BehaviorRelay<Int?>(value: nil)

    init(service: MarketDiscoveryService) {
        self.service = service

        subscribe(disposeBag, service.currentCategoryObservable) { [weak self] in self?.sync(currentCategory: $0) }
    }

    private func sync(currentCategory: MarketDiscoveryFilter?) {
        var index: Int?

        if let currentCategory = currentCategory {
            index = MarketDiscoveryFilter.allCases.firstIndex(of: currentCategory)
        }

        selectedFilterIndexRelay.accept(index)
    }

}

extension MarketDiscoveryViewModel {

    var selectedFilterIndexDriver: Driver<Int?> {
        selectedFilterIndexRelay.asDriver()
    }

    func setFilter(at index: Int?) {
        if let index = index, index < MarketDiscoveryFilter.allCases.count {
            service.currentCategory = MarketDiscoveryFilter.allCases[index]
        } else {
            service.currentCategory = nil
        }
    }

    func resetCategory() {
        if service.currentCategory != nil {
            service.currentCategory = nil
        }
    }

}

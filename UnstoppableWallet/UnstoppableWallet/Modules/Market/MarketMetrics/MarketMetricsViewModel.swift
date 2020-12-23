import RxSwift
import RxCocoa

class MarketMetricsViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketMetricsService

    private let metricsRelay = BehaviorRelay<MarketMetricsService.MarketMetrics?>(value: nil)

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private var isLoading: Bool = false

    private let errorRelay = BehaviorRelay<String?>(value: nil)
    private var error: String?

    init(service: MarketMetricsService) {
        self.service = service

        subscribe(disposeBag, service.marketMetricsObservable) { [weak self] in self?.sync(marketMetrics: $0) }
    }

    private func sync(marketMetrics: DataStatus<MarketMetricsService.MarketMetrics>) {
        if let data = marketMetrics.data {
            metricsRelay.accept(data)
        }
        isLoadingRelay.accept(marketMetrics.isLoading)
        errorRelay.accept(marketMetrics.error?.smartDescription)
    }

}

extension MarketMetricsViewModel {

    var metricsDriver: Driver<MarketMetricsService.MarketMetrics?> {
        metricsRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var errorDriver: Driver<String?> {
        errorRelay.asDriver()
    }

    public func refresh() {
        service.refresh()
    }

}

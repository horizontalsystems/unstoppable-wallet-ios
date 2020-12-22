import Foundation

class MarketMetricsViewModel {
    private let disposeBag = DisposeBag()

    public let service: MarketMetricsService

    private let metricsRelay = BehaviourRelay<MarketMetrics?>(value: nil)
    private var metrics: MarketMetrics?

    private let isLoadingRelay = BehaviourRelay<Bool>(value: false)
    private var isLoading: Bool = false

    private let errorRelay = BehaviourRelay<String?>(value: nil)
    private var error: String?

    init(service: MarketMetricsService) {
        self.service = service

        subscribe(disposeBag, service.marketMetricsObservable) { [weak self] in self?.sync(marketMetrics: $0) }
    }

    private func sync(marketMetrics: DataStatus<MarketMetrics>) {
        if let data = marketMetrics.data {
            metricsRelay.accept(data)
        }
        isLoadingRelay.accept(marketMetrics.isLoading)
        errorRelay.accept(marketMetrics.error?.smartDescription)
    }

}

extension MarketMetricsViewModel {

    var metricsDriver: Driver<MarketMetrics?> {
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

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import XRatesKit
import Chart

class CoinChartViewModel {
    private let service: CoinChartService
    private let factory: CoinChartFactory
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let rateRelay = BehaviorRelay<String?>(value: nil)
    private let rateDiffRelay = BehaviorRelay<Decimal?>(value: nil)
    private let chartInfoRelay = BehaviorRelay<CoinChartViewModel.ViewItem?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinChartService, factory: CoinChartFactory) {
        self.service = service
        self.factory = factory

        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }

        sync(state: service.state)
    }

    private func sync(state: DataStatus<CoinChartService.Item>) {
        loadingRelay.accept(state.isLoading)
        errorRelay.accept(state.error?.smartDescription)
        if state.error != nil {
            rateRelay.accept(nil)
            rateDiffRelay.accept(nil)
            chartInfoRelay.accept(nil)

            return
        }

        rateRelay.accept(state.data?.rate?.description ?? "") //todo: Convert!
        rateDiffRelay.accept(state.data?.rateDiff24h)

        guard let item = state.data else {
            chartInfoRelay.accept(nil)
            return
        }

        chartInfoRelay.accept(factory.convert(item: item, chartType: service.chartType, currency: service.currency, selectedIndicator: service.selectedIndicator))
    }

}

extension CoinChartViewModel {

        var loadingDriver: Driver<Bool> {
            loadingRelay.asDriver()
        }

        var rateDriver: Driver<String?> {
            rateRelay.asDriver()
        }

        var rateDiffDriver: Driver<Decimal?> {
            rateDiffRelay.asDriver()
        }

        var chartInfoDriver: Driver<CoinChartViewModel.ViewItem?> {
            chartInfoRelay.asDriver()
        }

        var errorDriver: Driver<String?> {
            errorRelay.asDriver()
        }

}

extension CoinChartViewModel {

    struct ViewItem {
        let chartData: ChartData

        let chartTrend: MovementTrend
        let chartDiff: Decimal?

        let trends: [ChartIndicatorSet: MovementTrend]

        let minValue: String?
        let maxValue: String?

        let timeline: [ChartTimelineItem]

        let selectedIndicator: ChartIndicatorSet
    }

}
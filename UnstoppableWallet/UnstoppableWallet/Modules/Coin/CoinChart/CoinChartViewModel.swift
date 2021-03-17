import Foundation
import RxSwift
import RxRelay
import RxCocoa
import XRatesKit

class CoinChartViewModel {
    private let service: CoinChartService
    private let disposeBag = DisposeBag()

    private let loadingRelay = BehaviorRelay<Bool>(value: false)
    private let rateRelay = BehaviorRelay<String?>(value: nil)
    private let rateDiffRelay = BehaviorRelay<Decimal?>(value: nil)
    private let chartInfoRelay = BehaviorRelay<ChartInfo?>(value: nil)
    private let errorRelay = BehaviorRelay<String?>(value: nil)

    init(service: CoinChartService) {
        self.service = service

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

        rateRelay.accept(state.data?.rate.description) //todo: Convert!
        rateDiffRelay.accept(state.data?.rateDiff24h)
        chartInfoRelay.accept(state.data?.chartInfo)
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

        var chartInfoDriver: Driver<ChartInfo?> {
            chartInfoRelay.asDriver()
        }

        var errorDriver: Driver<String?> {
            errorRelay.asDriver()
        }

}

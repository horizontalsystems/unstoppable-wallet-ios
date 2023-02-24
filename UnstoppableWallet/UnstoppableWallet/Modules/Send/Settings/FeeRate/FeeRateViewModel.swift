import RxSwift
import RxRelay
import RxCocoa
import Foundation

class FeeRateViewModel {
    private let disposeBag = DisposeBag()

    private let service: FeeRateService

    private let alteredStateRelay = PublishRelay<Void>()
    private let feeRateRelay = BehaviorRelay<Decimal?>(value: nil)

    init(service: FeeRateService) {
        self.service = service

        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(feeRateStatus: $0) }
        subscribe(disposeBag, service.usingRecommendedObservable) { [weak self] in self?.sync(usingRecommended: $0) }
        sync(feeRateStatus: service.status)
    }


    private func sync(feeRateStatus: DataStatus<Int>) {
        if case .completed(let feeRate) = feeRateStatus {
            feeRateRelay.accept(Decimal(feeRate))
        } else {
            feeRateRelay.accept(nil)
        }
    }

    private func sync(usingRecommended: Bool) {
        alteredStateRelay.accept(Void())
    }

}

extension FeeRateViewModel {

    var altered: Bool {
        !service.usingRecommended
    }

    var alteredStateSignal: Signal<Void> {
        alteredStateRelay.asSignal()
    }

    var feeRateDriver: Driver<Decimal?> {
        feeRateRelay.asDriver()
    }

    func set(value: Decimal) {
        service.set(feeRate: NSDecimalNumber(decimal: value).intValue)
    }

    func reset() {
        service.setRecommendedFeeRate()
    }

}

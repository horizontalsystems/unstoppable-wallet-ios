import Foundation
import RxCocoa
import RxRelay
import RxSwift

class FeeRateViewModel {
    private let disposeBag = DisposeBag()

    private let service: FeeRateService
    private let feeCautionViewModel: SendFeeCautionViewModel
    private let amountCautionViewModel: SendFeeSettingsAmountCautionViewModel

    private let alteredStateRelay = PublishRelay<Void>()
    private let feeRateRelay = BehaviorRelay<Decimal?>(value: nil)
    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(service: FeeRateService, feeCautionViewModel: SendFeeCautionViewModel, amountCautionViewModel: SendFeeSettingsAmountCautionViewModel) {
        self.service = service
        self.feeCautionViewModel = feeCautionViewModel
        self.amountCautionViewModel = amountCautionViewModel

        subscribe(disposeBag, feeCautionViewModel.cautionDriver) { [weak self] _ in self?.syncCaution() }
        subscribe(disposeBag, amountCautionViewModel.amountCautionDriver) { [weak self] _ in self?.syncCaution() }

        subscribe(disposeBag, service.statusObservable) { [weak self] in self?.sync(feeRateStatus: $0) }
        subscribe(disposeBag, service.usingRecommendedObservable) { [weak self] in self?.sync(usingRecommended: $0) }
        sync(feeRateStatus: service.status)
        syncCaution()
    }

    private func syncCaution() {
        var caution: TitledCaution?

        if let amountCaution = amountCautionViewModel.amountCaution {
            caution = amountCaution
        } else if let feeCaution = feeCautionViewModel.caution {
            caution = feeCaution
        }

        cautionRelay.accept(caution)
    }

    private func sync(feeRateStatus: DataStatus<Int>) {
        if case let .completed(feeRate) = feeRateStatus {
            feeRateRelay.accept(Decimal(feeRate))
        } else {
            feeRateRelay.accept(nil)
        }
    }

    private func sync(usingRecommended _: Bool) {
        alteredStateRelay.accept(())
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

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }
}

import Foundation
import RxSwift
import RxRelay
import RxCocoa

class SendFeeCautionViewModel {
    private let disposeBag = DisposeBag()
    private let service: FeeRateService

    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)
    var caution: TitledCaution? {
        didSet {
            if oldValue != caution {
                cautionRelay.accept(caution)
            }
        }
    }

    init(service: FeeRateService) {
        self.service = service

        subscribe(disposeBag, service.statusObservable) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        guard service.feeRateAvailble else {
            caution = TitledCaution(title: "send.fee_settings.fee_error.title".localized, text: "send.fee_settings.fee_rate_unavailable".localized, type: .error)
            return
        }

        if case let .completed(feeRate) = service.status, service.recommendedFeeRate > feeRate {
            if service.minimumFeeRate <= feeRate {
                caution = TitledCaution(title: "send.fee_settings.stuck_warning.title".localized, text: "send.fee_settings.stuck_warning".localized, type: .warning)
            } else {
                caution = TitledCaution(title: "send.fee_settings.fee_error.title".localized, text: "send.fee_settings.too_low".localized, type: .error)
            }
        } else {
            caution = nil
        }
    }

}

extension SendFeeCautionViewModel: ITitledCautionViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}

import RxSwift
import RxRelay
import RxCocoa

class SendXFeeWarningViewModel {
    static private let stuckWarningString = "send.stuck_warning".localized

    private let disposeBag = DisposeBag()
    private let service: SendXFeeRateService

    private let warningRelay = BehaviorRelay<String?>(value: nil)
    private var warning: String? {
        didSet {
            if oldValue != warning {
                warningRelay.accept(warning)
            }
        }
    }

    init(service: SendXFeeRateService) {
        self.service = service

        subscribe(disposeBag, service.recommendedFeeRateObservable) { [weak self] _ in self?.sync() }
        subscribe(disposeBag, service.feeRateObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        if case let .completed(feeRate) = service.feeRate,
           let recommendedFeeRate = service.recommendedFeeRate,
           recommendedFeeRate > feeRate {
            warning = Self.stuckWarningString
        } else {
            warning = nil
        }
    }

}

extension SendXFeeWarningViewModel {

    var warningDriver: Driver<String?> {
        warningRelay.asDriver()
    }

}

import RxSwift
import RxRelay
import RxCocoa

class SendFeeWarningViewModel {

    private let disposeBag = DisposeBag()
    private let service: FeeRateService
    private let cautionTitle: String
    private let cautionText: String

    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)
    private var caution: TitledCaution? {
        didSet {
            if oldValue != caution {
                cautionRelay.accept(caution)
            }
        }
    }

    init(service: FeeRateService, cautionTitle: String = "send.fee_settings.stuck_warning.title".localized, cautionText: String = "send.fee_settings.stuck_warning".localized) {
        self.service = service
        self.cautionTitle = cautionTitle
        self.cautionText = cautionText

        subscribe(disposeBag, service.statusObservable) { [weak self] _ in self?.sync() }
    }

    private func sync() {
        if case let .completed(feeRate) = service.status, service.recommendedFeeRate > feeRate {
            caution = TitledCaution(title: cautionTitle, text: cautionText, type: .warning)
        } else {
            caution = nil
        }
    }

}

extension SendFeeWarningViewModel: ITitledCautionViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}

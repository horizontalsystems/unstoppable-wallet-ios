import RxSwift
import RxCocoa

class SendSettingsViewModel {
    let feeCautionViewModel: SendFeeWarningViewModel
    let amountCautionViewModel: SendFeeSettingsAmountCautionViewModel

    private let disposeBag = DisposeBag()

    private let cautionRelay = BehaviorRelay<TitledCaution?>(value: nil)

    init(feeCautionViewModel: SendFeeWarningViewModel, amountCautionViewModel: SendFeeSettingsAmountCautionViewModel) {
        self.feeCautionViewModel = feeCautionViewModel
        self.amountCautionViewModel = amountCautionViewModel

        subscribe(disposeBag, feeCautionViewModel.cautionDriver) { [weak self] _ in self?.sync() }
        subscribe(disposeBag, amountCautionViewModel.amountCautionDriver) { [weak self] _ in self?.sync() }
        sync()
    }

    private func sync() {
        var caution: TitledCaution? = nil

        if let error = amountCautionViewModel.amountCaution {
            caution = error
        } else if let warning = feeCautionViewModel.caution {
            caution = warning
        }

        cautionRelay.accept(caution)
    }

}

extension SendSettingsViewModel {

    var cautionDriver: Driver<TitledCaution?> {
        cautionRelay.asDriver()
    }

}

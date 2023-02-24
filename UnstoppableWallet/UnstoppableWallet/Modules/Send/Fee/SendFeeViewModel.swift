import RxSwift
import RxRelay
import RxCocoa

class SendFeeViewModel {
    private let disposeBag = DisposeBag()

    private let service: SendFeeService

    private let valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)

    private var firstLoaded = false

    init(service: SendFeeService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(state: $0)
        }

    }

    private func sync(state: DataStatus<SendFeeService.State>) {
        switch state {
        case .loading:
            guard firstLoaded else {
                spinnerVisibleRelay.accept(true)
                valueRelay.accept(nil)
                return
            }

            spinnerVisibleRelay.accept(false)
        case .failed:
            spinnerVisibleRelay.accept(false)

            valueRelay.accept(.error(text: "n/a".localized))
        case .completed(let state):
            spinnerVisibleRelay.accept(false)
            firstLoaded = true

            guard !state.primaryInfo.value.isZero else {
                valueRelay.accept(.disabled(text: "n/a".localized))
                return
            }

            valueRelay.accept(.regular(text: state.primaryInfo.formattedFull ?? "n/a".localized, secondaryText: state.secondaryInfo?.formattedFull))
        }
    }

}

extension SendFeeViewModel: IFeeViewModel {

    var valueDriver: Driver<FeeCell.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

}

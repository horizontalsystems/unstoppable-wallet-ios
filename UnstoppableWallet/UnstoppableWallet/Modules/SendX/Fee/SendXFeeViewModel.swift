import RxSwift
import RxRelay
import RxCocoa

class SendXFeeViewModel {
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

            valueRelay.accept(FeeCell.Value(text: "n/a".localized, type: .error))
        case .completed(let state):
            spinnerVisibleRelay.accept(false)
            firstLoaded = true

            let text = [state.primaryInfo, state.secondaryInfo]
                    .compactMap {
                        $0?.formattedString
                    }
                    .joined(separator: " | ")

            valueRelay.accept(FeeCell.Value(text: text, type: .regular))
        }
    }

}

extension SendXFeeViewModel: IFeeViewModel {

    var valueDriver: Driver<FeeCell.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

}

import Combine
import RxCocoa
import RxRelay
import RxSwift

class SendFeeViewModel: ObservableObject {
    private let disposeBag = DisposeBag()

    private let service: SendFeeService

    private var valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private var spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)

    @Published var value: FeeCell.Value? = nil
    @Published var spinnerVisible: Bool = false

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
                spinnerVisible = true
                valueRelay.accept(nil)
                value = nil
                return
            }

            spinnerVisibleRelay.accept(false)
            spinnerVisible = false
        case .failed:
            spinnerVisibleRelay.accept(false)
            spinnerVisible = false

            valueRelay.accept(.error(text: "n/a".localized))
            value = .error(text: "n/a".localized)
        case let .completed(state):
            spinnerVisibleRelay.accept(false)
            spinnerVisible = false
            firstLoaded = true

            guard !state.primaryInfo.value.isZero else {
                valueRelay.accept(.disabled(text: "n/a".localized))
                value = .disabled(text: "n/a".localized)
                return
            }

            let regular: FeeCell.Value = .regular(text: state.primaryInfo
                .formattedFull ?? "n/a".localized, secondaryText: state.secondaryInfo?.formattedFull)
            valueRelay.accept(regular)
            value = regular
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

import RxSwift
import RxRelay
import RxCocoa

class SendFeeViewModel {
    private let disposeBag = DisposeBag()

    private let service: ISendFeeService

    private let valueRelay = BehaviorRelay<FeeCell.Value?>(value: nil)
    private let spinnerVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let editButtonVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let editButtonHighlightedRelay = BehaviorRelay<Bool>(value: false)

    private var firstLoaded = false

    init(service: ISendFeeService) {
        self.service = service

        subscribe(disposeBag, service.stateObservable) { [weak self] in
            self?.sync(state: $0)
        }

        subscribe(disposeBag, service.editableObservable) { [weak self] in
            self?.editButtonVisibleRelay.accept($0)
        }

        subscribe(disposeBag, service.defaultFeeObservable) { [weak self] in
            self?.editButtonHighlightedRelay.accept(!$0)
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

            guard !state.primaryInfo.value.isZero else {
                valueRelay.accept(FeeCell.Value(text: "n/a".localized, type: .disabled))
                return
            }

            let text = [state.primaryInfo, state.secondaryInfo]
                    .compactMap {
                        $0?.formattedFull
                    }
                    .joined(separator: " | ")

            valueRelay.accept(FeeCell.Value(text: text, type: .regular))
        }
    }

}

extension SendFeeViewModel: IEditableFeeViewModel {

    var hasInformation: Bool {
        false
    }

    var title: String {
        "fee_settings.fee".localized
    }

    var valueDriver: Driver<FeeCell.Value?> {
        valueRelay.asDriver()
    }

    var spinnerVisibleDriver: Driver<Bool> {
        spinnerVisibleRelay.asDriver()
    }

    var editButtonVisibleDriver: Driver<Bool> {
        editButtonVisibleRelay.asDriver()
    }

    var editButtonHighlightedDriver: Driver<Bool> {
        editButtonHighlightedRelay.asDriver()
    }

}

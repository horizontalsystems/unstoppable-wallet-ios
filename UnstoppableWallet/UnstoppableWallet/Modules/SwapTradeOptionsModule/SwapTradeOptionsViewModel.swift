import RxSwift
import RxCocoa

class SwapTradeOptionsViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapTradeOptionsService
    private let decimalParser: IAmountDecimalParser

    private let applyEnabledRelay = BehaviorRelay<Bool>(value: true)

    public var slippageViewModel: SwapSlippageViewModel {
        SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())
    }

    public var deadlineViewModel: SwapDeadlineViewModel {
        SwapDeadlineViewModel(service: service, decimalParser: AmountDecimalParser())
    }

    public var recipientViewModel: RecipientAddressViewModel {
        RecipientAddressViewModel(service: service)
    }

    init(service: SwapTradeOptionsService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.decimalParser = decimalParser

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.stateObservable) { [weak self] state in
            switch state {
            case .valid: self?.applyEnabledRelay.accept(true)
            case .invalid: self?.applyEnabledRelay.accept(false)
            }
        }
    }

}

extension SwapTradeOptionsViewModel {

    public var applyEnabledDriver: Driver<Bool> {
        applyEnabledRelay.asDriver()
    }

}

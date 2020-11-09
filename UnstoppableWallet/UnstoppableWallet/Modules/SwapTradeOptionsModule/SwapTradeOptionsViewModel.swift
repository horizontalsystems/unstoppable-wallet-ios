import RxSwift
import RxCocoa

class SwapTradeOptionsViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapTradeOptionsService
    private let swapService: SwapService
    private let decimalParser: IAmountDecimalParser

    private let validStateRelay = BehaviorRelay<Bool>(value: true)

    public var slippageViewModel: SwapSlippageViewModel {
        SwapSlippageViewModel(service: service, decimalParser: AmountDecimalParser())
    }

    public var deadlineViewModel: SwapDeadlineViewModel {
        SwapDeadlineViewModel(service: service, decimalParser: AmountDecimalParser())
    }

    public var recipientViewModel: RecipientAddressViewModel {
        RecipientAddressViewModel(service: service)
    }

    init(service: SwapTradeOptionsService, swapService: SwapService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.swapService = swapService
        self.decimalParser = decimalParser

        subscribeToService()
    }

    private func subscribeToService() {
        subscribe(disposeBag, service.stateObservable) { [weak self] state in
            switch state {
            case .valid: self?.validStateRelay.accept(true)
            case .invalid: self?.validStateRelay.accept(false)
            }
        }
    }

}

extension SwapTradeOptionsViewModel {

    public var validStateDriver: Driver<Bool> {
        validStateRelay.asDriver()
    }

    public func doneDidTap() -> Bool {
        if case let .valid(tradeOptions) = service.state {
            swapService.tradeOptions = tradeOptions
            return true
        }
        return false
    }

}

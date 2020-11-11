import RxSwift
import RxCocoa

class SwapTradeOptionsViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapTradeOptionsService
    private let tradeService: SwapTradeService
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

    init(service: SwapTradeOptionsService, tradeService: SwapTradeService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.tradeService = tradeService
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
            tradeService.tradeOptions = tradeOptions
            return true
        }
        return false
    }

}

extension SwapTradeOptionsService.TradeOptionsError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .invalidSlippage(let type):
            switch type {
            case .lower: return "swap.advanced_settings.error.lower_slippage".localized
            case .higher(let max): return "swap.advanced_settings.error.higher_slippage".localized(max.description)
            }
        case .invalidAddress: return "send.error.invalid_address".localized
        default: return nil
        }
    }

}

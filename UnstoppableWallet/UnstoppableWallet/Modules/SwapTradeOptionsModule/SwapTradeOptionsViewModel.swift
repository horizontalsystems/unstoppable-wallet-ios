import RxSwift
import RxCocoa

class SwapTradeOptionsViewModel {
    private let disposeBag = DisposeBag()

    private let service: SwapTradeOptionsService
    private let tradeService: SwapTradeService
    private let decimalParser: IAmountDecimalParser

    private let actionRelay = BehaviorRelay<ActionState>(value: .enabled)

    init(service: SwapTradeOptionsService, tradeService: SwapTradeService, decimalParser: IAmountDecimalParser) {
        self.service = service
        self.tradeService = tradeService
        self.decimalParser = decimalParser

        service.stateObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.syncAction()
                })
                .disposed(by: disposeBag)
    }

    private func syncAction() {
        switch service.state {
        case .valid:
            actionRelay.accept(.enabled)
        case .invalid:
            guard let error = service.errors.first else {
                return
            }

            switch error {
            case is SwapTradeOptionsService.AddressError:
                actionRelay.accept(.disabled(title: "swap.advanced_settings.error.invalid_address".localized))
            case is SwapTradeOptionsService.SlippageError:
                actionRelay.accept(.disabled(title: "swap.advanced_settings.error.invalid_slippage".localized))
            case is SwapTradeOptionsService.DeadlineError:
                actionRelay.accept(.disabled(title: "swap.advanced_settings.error.invalid_deadline".localized))
            default: ()
            }
        }
    }

}

extension SwapTradeOptionsViewModel {

    public var actionDriver: Driver<ActionState> {
        actionRelay.asDriver()
    }

    public func doneDidTap() -> Bool {
        if case let .valid(tradeOptions) = service.state {
            tradeService.swapTradeOptions = tradeOptions
            return true
        }
        return false
    }

}

extension SwapTradeOptionsService.AddressError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .invalidAddress: return "send.error.invalid_address".localized
        }
    }

}

extension SwapTradeOptionsService.SlippageError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .tooLow: return "swap.advanced_settings.error.lower_slippage".localized
        case .tooHigh(let max): return "swap.advanced_settings.error.higher_slippage".localized(max.description)
        default: return nil
        }
    }

}

extension SwapTradeOptionsViewModel {

    enum ActionState {
        case enabled
        case disabled(title: String)
    }

}

import RxSwift
import RxCocoa

class UniswapSettingsViewModel {
    private let disposeBag = DisposeBag()

    private let service: UniswapSettingsService
    private let tradeService: UniswapTradeService

    private let actionRelay = BehaviorRelay<ActionState>(value: .enabled)

    init(service: UniswapSettingsService, tradeService: UniswapTradeService) {
        self.service = service
        self.tradeService = tradeService

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
            case is SwapSettingsModule.AddressError:
                actionRelay.accept(.disabled(title: "swap.advanced_settings.error.invalid_address".localized))
            case is SwapSettingsModule.SlippageError:
                actionRelay.accept(.disabled(title: "swap.advanced_settings.error.invalid_slippage".localized))
            case is SwapSettingsModule.DeadlineError:
                actionRelay.accept(.disabled(title: "swap.advanced_settings.error.invalid_deadline".localized))
            default: ()
            }
        }
    }

}

extension UniswapSettingsViewModel {

    public var actionDriver: Driver<ActionState> {
        actionRelay.asDriver()
    }

    public func doneDidTap() -> Bool {
        if case let .valid(tradeOptions) = service.state {
            tradeService.settings = tradeOptions
            return true
        }
        return false
    }

}

extension UniswapSettingsViewModel {

    enum ActionState {
        case enabled
        case disabled(title: String)
    }

}

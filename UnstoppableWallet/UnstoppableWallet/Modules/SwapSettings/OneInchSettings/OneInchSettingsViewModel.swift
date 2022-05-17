import RxSwift
import RxCocoa

class OneInchSettingsViewModel {
    private let disposeBag = DisposeBag()

    private let service: OneInchSettingsService
    private let tradeService: OneInchTradeService

    private let actionRelay = BehaviorRelay<ActionState>(value: .enabled)

    init(service: OneInchSettingsService, tradeService: OneInchTradeService) {
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
            default: ()
            }
        }
    }

}

extension OneInchSettingsViewModel {

    public var actionDriver: Driver<ActionState> {
        actionRelay.asDriver()
    }

    public func doneDidTap() -> Bool {
        if case let .valid(settings) = service.state {
            tradeService.settings = settings
            return true
        }
        return false
    }

}

extension OneInchSettingsViewModel {

    enum ActionState {
        case enabled
        case disabled(title: String)
    }

}

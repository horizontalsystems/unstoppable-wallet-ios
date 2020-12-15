import RxSwift
import RxCocoa

class RecipientAddressViewModel {
    private let service: SwapTradeOptionsService
    private let disposeBag = DisposeBag()

    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)

    init(service: SwapTradeOptionsService) {
        self.service = service

        service.errorsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] in
                    self?.update(errors: $0)
                })
                .disposed(by: disposeBag)
    }

    private func update(errors: [Error]) {
        let error = errors.first(where: {
            if case .invalidAddress = $0 as? SwapTradeOptionsService.TradeOptionsError {
                return true
            }
            return false
        })

        cautionRelay.accept(error.map { Caution(text: $0.smartDescription, type: .error) })
    }

}

extension RecipientAddressViewModel {

    var initialValue: String? {
        guard case let .valid(tradeOptions) = service.state else {
            return nil
        }

        return tradeOptions.recipient?.hex
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    func onChange(text: String?) {
        service.recipient = text
    }

}

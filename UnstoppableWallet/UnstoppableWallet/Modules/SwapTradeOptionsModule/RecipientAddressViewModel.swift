import RxSwift
import RxCocoa

class RecipientAddressViewModel {
    private let service: SwapTradeOptionsService
    private let resolutionService = AddressResolutionService()
    private let disposeBag = DisposeBag()

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private var editing = false
    private var forceShowError = false

    init(service: SwapTradeOptionsService) {
        self.service = service

        service.errorsObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                })
                .disposed(by: disposeBag)

        resolutionService.addressObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] address in
                    self?.service.recipient = address
                })
                .disposed(by: disposeBag)

        resolutionService.isResolvingObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] isResolving in
                    self?.sync()
                    self?.isLoadingRelay.accept(isResolving)

                    if isResolving {
                        self?.forceShowError = true
                    }
                })
                .disposed(by: disposeBag)

        sync()
    }

    private func sync() {
        let error = service.errors.first(where: { $0 is SwapTradeOptionsService.AddressError })

        if (editing && !forceShowError) || resolutionService.isResolving {
            cautionRelay.accept(nil)
        } else {
            cautionRelay.accept(error.map { Caution(text: $0.smartDescription, type: .error) })
        }
    }

}

extension RecipientAddressViewModel {

    var initialValue: String? {
        guard case let .valid(tradeOptions) = service.state else {
            return nil
        }

        return tradeOptions.recipient?.title
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    func onChange(text: String?) {
        forceShowError = false

        resolutionService.set(text: text)
    }

    func onChange(editing: Bool) {
        if editing {
            forceShowError = true
        }

        self.editing = editing
        sync()
    }

}

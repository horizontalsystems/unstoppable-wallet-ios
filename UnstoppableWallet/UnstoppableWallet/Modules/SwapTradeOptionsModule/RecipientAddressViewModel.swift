import RxSwift
import RxCocoa

protocol IRecipientAddressService {
    var initialAddress: Address? { get }
    var error: Error? { get }
    var errorObservable: Observable<Error?> { get }
    func set(address: Address?)
    func set(amount: Decimal)
}

class RecipientAddressViewModel {
    private let service: IRecipientAddressService
    private let resolutionService: AddressResolutionService
    private let addressParser: IAddressParser
    private let isResolutionEnabled: Bool
    private let disposeBag = DisposeBag()

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let setTextRelay = PublishRelay<String?>()
    private var editing = false
    private var forceShowError = false

    init(service: IRecipientAddressService, resolutionService: AddressResolutionService, addressParser: IAddressParser, isResolutionEnabled: Bool = true) {
        self.service = service
        self.resolutionService = resolutionService
        self.addressParser = addressParser
        self.isResolutionEnabled = isResolutionEnabled

        service.errorObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] _ in
                    self?.sync()
                })
                .disposed(by: disposeBag)

        resolutionService.addressObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(MainScheduler.instance) // todo: required for current Send module, remove this after refactoring to MVVM
                .subscribe(onNext: { [weak self] address in
                    self?.service.set(address: address)
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
        if (editing && !forceShowError) || resolutionService.isResolving {
            cautionRelay.accept(nil)
        } else {
            cautionRelay.accept(service.error.map { Caution(text: $0.smartDescription, type: .error) })
        }
    }

}

extension RecipientAddressViewModel {

    var initialValue: String? {
        service.initialAddress?.title
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var setTextSignal: Signal<String?> {
        setTextRelay.asSignal()
    }

    func onChange(text: String?) {
        forceShowError = false

        service.set(address: text.map { Address(raw: $0) })

        if isResolutionEnabled {
            resolutionService.set(text: text)
        }
    }

    func onFetch(text: String?) {
        guard let text = text, !text.isEmpty else {
            return
        }

        let addressData = addressParser.parse(paymentAddress: text)

        setTextRelay.accept(addressData.address)

        if let amount = addressData.amount {
            service.set(amount: Decimal(amount))
        }
    }

    func onChange(editing: Bool) {
        if editing {
            forceShowError = true
        }

        self.editing = editing
        sync()
    }

}

import RxSwift
import RxCocoa

protocol IRecipientAddressService {
    var addressState: AddressService.State { get }
    var addressStateObservable: Observable<AddressService.State> { get }
    var recipientError: Error? { get }
    var recipientErrorObservable: Observable<Error?> { get }
    func set(address: Address?)
    func set(amount: Decimal)
}

class RecipientAddressViewModel {
    private let disposeBag = DisposeBag()
    private let service: AddressService
    private let handlerDelegate: IRecipientAddressService? // for legacy handlers

    private let isSuccessRelay = BehaviorRelay<Bool>(value: false)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let setTextRelay = BehaviorRelay<String?>(value: nil)

    private var editing = false

    init(service: AddressService, handlerDelegate: IRecipientAddressService?) {
        self.service = service
        self.handlerDelegate = handlerDelegate

        subscribe(disposeBag, service.stateObservable) { [weak self] state in
            self?.sync(state: state)
        }

        sync(state: service.state)
    }

    private func sync(state: AddressService.State) {
        switch state {
        case .empty:
            cautionRelay.accept(nil)
            isSuccessRelay.accept(false)
            isLoadingRelay.accept(false)

            handlerDelegate?.set(address: nil)
        case .loading:
            cautionRelay.accept(nil)
            isSuccessRelay.accept(false)
            isLoadingRelay.accept(true)

            handlerDelegate?.set(address: nil)
        case .validationError:
            cautionRelay.accept(editing ? nil : Caution(text: AddressService.AddressError.invalidAddress.smartDescription, type: .error))
            isSuccessRelay.accept(false)
            isLoadingRelay.accept(false)

            handlerDelegate?.set(address: nil)
        case .fetchError:
            cautionRelay.accept(Caution(text: AddressService.AddressError.invalidAddress.smartDescription, type: .error))
            isSuccessRelay.accept(false)
            isLoadingRelay.accept(false)

            handlerDelegate?.set(address: nil)
        case .success(let address):
            setTextRelay.accept(address.title)
            cautionRelay.accept(nil)
            isSuccessRelay.accept(true)
            isLoadingRelay.accept(false)

            handlerDelegate?.set(address: address)
        }

    }

}

extension RecipientAddressViewModel {

    var isSuccessDriver: Driver<Bool> {
        isSuccessRelay.asDriver()
    }

    var isLoadingDriver: Driver<Bool> {
        isLoadingRelay.asDriver()
    }

    var cautionDriver: Driver<Caution?> {
        cautionRelay.asDriver()
    }

    var setTextDriver: Driver<String?> {
        setTextRelay.asDriver()
    }

    func onChange(text: String?) {
        service.set(text: text ?? "")
    }

    func onFetch(text: String?) {
        let text = service.handleFetched(text: text ?? "")
        setTextRelay.accept(text)
    }

    func onChange(editing: Bool) {
        self.editing = editing
        sync(state: service.state)
    }

}

extension AddressService.AddressError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .invalidAddress: return "send.error.invalid_address".localized
        }
    }

}

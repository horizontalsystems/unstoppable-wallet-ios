import RxSwift
import RxCocoa

protocol IRecipientAddressService {
    var addressState: AddressParserChain.State { get }
    var addressStateObservable: Observable<AddressParserChain.State> { get }
    var recipientError: Error? { get }
    var recipientErrorObservable: Observable<Error?> { get }
    func set(address: String?)
    func set(amount: Decimal)
}

class RecipientAddressViewModel {
    private let service: IRecipientAddressService
    private let addressParser: IAddressParser
    private let disposeBag = DisposeBag()

    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    private let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let setTextRelay = PublishRelay<String?>()

    private var editing = false
    private var forceShowError = false

    init(service: IRecipientAddressService, addressParser: IAddressParser) {
        self.service = service
        self.addressParser = addressParser

        subscribe(disposeBag, service.addressStateObservable) { [weak self] addressState in
            self?.sync(addressState: addressState)
        }

        sync(addressState: service.addressState)
    }

    private func sync(addressState: AddressParserChain.State) {
        switch addressState {
        case .empty:
            cautionRelay.accept(nil)
            isLoadingRelay.accept(false)
        case .loading:
            cautionRelay.accept(nil)
            isLoadingRelay.accept(true)
        case .validationError(let error):
            cautionRelay.accept(editing ? nil : Caution(text: error.smartDescription, type: .error))
            isLoadingRelay.accept(false)
        case .fetchError(let error):
            cautionRelay.accept(Caution(text: error.smartDescription, type: .error))
            isLoadingRelay.accept(false)
        case .success:
            cautionRelay.accept(nil)
            isLoadingRelay.accept(false)
        }

    }

}

extension RecipientAddressViewModel {

    var initialValue: String? {
        if case let .success(address) = service.addressState {
            return address.title
        }

        return nil
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
        service.set(address: text)
    }

    func onFetch(text: String?) {
        guard let text = text, !text.isEmpty else {
            return
        }

        let addressData = addressParser.parse(paymentAddress: text)

        setTextRelay.accept(addressData.address)
        onChange(text: addressData.address)

        if let amount = addressData.amount {
            service.set(amount: Decimal(amount))
        }
    }

    func onChange(editing: Bool) {
        self.editing = editing
        sync(addressState: service.addressState)
    }

}

extension SwapSettingsModule.AddressError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .invalidAddress: return "send.error.invalid_address".localized
        }
    }

}

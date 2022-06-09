import Foundation
import RxSwift
import RxCocoa

protocol IAmountPublishService: AnyObject {
    var publishAmountRelay: PublishRelay<Decimal> { get }
}

class AddressService {
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "io.horizontalsystems.unstoppable.address-service")

    private let disposeBag = DisposeBag()
    private var addressParserDisposeBag = DisposeBag()
    private var customErrorDisposeBag = DisposeBag()

    private let addressUriParser: AddressUriParser
    private let addressParserChain: AddressParserChain

    weak var amountPublishService: IAmountPublishService?
    weak var customErrorService: IErrorService? {
        didSet {
            register(customErrorService: customErrorService)
        }
    }

    private var stateRelay = PublishRelay<State>()
    private(set) var state: State {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var customErrorRelay = PublishRelay<Error?>()
    private(set) var customError: Error? {
        didSet {
            customErrorRelay.accept(customError)
        }
    }

    init(addressUriParser: AddressUriParser, addressParserChain: AddressParserChain, initialAddress: Address? = nil) {
        self.addressUriParser = addressUriParser
        self.addressParserChain = addressParserChain

        if let initialAddress = initialAddress {
            state = .success(initialAddress)
        } else {
            state = .empty
        }
    }

    private func register(customErrorService: IErrorService?) {
        customErrorDisposeBag = DisposeBag()

        if let customErrorService = customErrorService {
            subscribe(disposeBag, customErrorService.errorObservable) { [weak self] in
                self?.sync(customError: $0)
            }
        }
    }

    private func sync(customError: Error?) {
        self.customError = customError
    }

    private func sync(address: Address?) {
        guard let address = address else {
            state = .empty
            return
        }

        state = .success(address)
    }

    private func sync(error: Error) {
        guard let error = error as? AddressParserChain.ParserError else {
            state = .fetchError(error)
            return
        }

        switch error {
        case .validationError: state = .validationError
        case .fetchError(let error): state = .fetchError(error)
        }
    }

}

extension AddressService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable().observeOn(scheduler)
    }

    var customErrorObservable: Observable<Error?> {
        customErrorRelay.asObservable().observeOn(scheduler)
    }

    func set(text: String) {
        guard !text.isEmpty else {
            state = .empty
            return
        }

        state = .loading
        addressParserDisposeBag = DisposeBag()

        addressParserChain
            .handle(address: text)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(
                onSuccess: { [weak self] in self?.sync(address: $0) },
                onError: { [weak self] in self?.sync(error: $0) }
            )
            .disposed(by: addressParserDisposeBag)
    }

    func handleFetched(text: String) -> String {
        let addressData = addressUriParser.parse(paymentAddress: text.trimmingCharacters(in: .whitespaces))

        if let amount = addressData.amount {
            amountPublishService?.publishAmountRelay.accept(Decimal(amount))
        }

        set(text: addressData.address)

        return addressData.address
    }

}

extension AddressService {

    enum State {
        case loading
        case empty
        case success(Address)
        case validationError
        case fetchError(Error)

        var address: Address? {
            if case let .success(address) = self {
                return address
            }
            return nil
        }

        var isLoading: Bool {
            if case .loading = self {
                return true
            }
            return false
        }

    }

    enum AddressError: Error {
        case invalidAddress
    }

}

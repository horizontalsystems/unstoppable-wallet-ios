import Foundation
import RxSwift
import RxCocoa

protocol IAmountPublishService: AnyObject {
    var amountRelay: PublishRelay<Decimal> { get }
}

class AddressService {
    private let disposeBag = DisposeBag()
    private var addressParserDisposeBag = DisposeBag()

    private let addressUriParser: AddressUriParser
    private let addressParserChain: AddressParserChain
    private weak var amountPublishService: IAmountPublishService?

    private var stateRelay = PublishRelay<State>()
    private(set) var state: State {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var text: String = ""

    init(addressUriParser: AddressUriParser, addressParserChain: AddressParserChain, initialAddress: Address? = nil) {
        self.addressUriParser = addressUriParser
        self.addressParserChain = addressParserChain

        if let initialAddress = initialAddress {
            state = .success(initialAddress)
        } else {
            state = .empty
        }

        subscribe(disposeBag, addressParserChain.itemUpdatedObservable) { [weak self] in self?.sync() }
    }

    private func sync() {
        set(text: text)
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
            state = .fetchError
            return
        }

        switch error {
        case .validationError: state = .validationError
        case .fetchError: state = .fetchError
        }
    }

}

extension AddressService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func set(text: String) {
        self.text = text

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
        let addressData = addressUriParser.parse(paymentAddress: text)

        if let amount = addressData.amount {
            amountPublishService?.amountRelay.accept(Decimal(amount))
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
        case fetchError

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

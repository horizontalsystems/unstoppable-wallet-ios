import Foundation
import RxSwift
import RxCocoa

protocol IAmountPublishService: AnyObject {
    var amountRelay: PublishRelay<Decimal> { get }
}

class AddressService {
    private var disposeBag = DisposeBag()
    private let addressUriParser: IAddressUriParser
    private let addressParserChain: AddressParserChain
    private weak var amountPublishService: IAmountPublishService?

    private var stateRelay = PublishRelay<State>()
    private(set) var state: State {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(addressUriParser: IAddressUriParser, addressParserChain: AddressParserChain, initialAddress: Address? = nil) {
        self.addressUriParser = addressUriParser
        self.addressParserChain = addressParserChain

        if let initialAddress = initialAddress {
            state = .success(initialAddress)
        } else {
            state = .empty
        }

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
        guard !text.isEmpty else {
            state = .empty
            return
        }

        state = .loading
        disposeBag = DisposeBag()

        addressParserChain
            .handle(address: text)
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
            .subscribe(
                onSuccess: { [weak self] in self?.sync(address: $0) },
                onError: { [weak self] in self?.sync(error: $0) }
            )
            .disposed(by: disposeBag)
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
    }

    enum AddressError: Error {
        case invalidAddress
    }

}

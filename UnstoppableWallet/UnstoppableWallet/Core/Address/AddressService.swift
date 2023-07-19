import Foundation
import RxSwift
import RxCocoa
import MarketKit

protocol IAmountPublishService: AnyObject {
    var publishAmountRelay: PublishRelay<Decimal> { get }
}

class AddressService {
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated, internalSerialQueueName: "\(AppConfig.label).address-service")

    private let disposeBag = DisposeBag()
    private let marketKit: MarketKit.Kit
    private var addressParserDisposeBag = DisposeBag()
    private var customErrorDisposeBag = DisposeBag()

    private var addressUriParser: AddressUriParser
    private var addressParserChain: AddressParserChain?

    private(set) var blockchainType: BlockchainType?
    private let contactBookManager: ContactBookManager?

    private let showContactsRelay = PublishRelay<Bool>()
    var showContacts: Bool {
        guard let contactBookManager, let blockchainType = blockchainType else {
            return false
        }

        return !contactBookManager.contacts(blockchainUid: blockchainType.uid).isEmpty
    }

    private var text: String = ""

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

    init(mode: Mode, marketKit: MarketKit.Kit, contactBookManager: ContactBookManager?, blockchainType: BlockchainType?, initialAddress: Address? = nil) {
        self.marketKit = marketKit
        self.blockchainType = blockchainType
        self.contactBookManager = contactBookManager

        switch mode {
            case .blockchainType:
            addressUriParser = AddressParserFactory.parser(blockchainType: blockchainType)
            addressParserChain = blockchainType.flatMap { AddressParserFactory.parserChain(blockchainType: $0) }
        case .parsers(let uriParser, let parserChain):
            addressUriParser = uriParser
            addressParserChain = parserChain
        }

        if let initialAddress = initialAddress {
            state = .success(initialAddress)
        } else {
            state = .empty
        }

        if let contactBookManager {
            subscribe(disposeBag, contactBookManager.stateObservable) { [weak self] _ in self?.showContactsRelay.accept(self?.showContacts ?? false) }
            showContactsRelay.accept(showContacts)
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
        case .validationError: state = .validationError(blockchainName: blockchainType.flatMap { try? marketKit.blockchain(uid: $0.uid) }?.name)
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

    var showContactsObservable: Observable<Bool> {
        showContactsRelay.asObservable()
    }

    func set(text: String) {
        self.text = text
        guard !text.isEmpty else {
            state = .empty
            return
        }

        guard let addressParserChain = addressParserChain else {
            sync(address: Address(raw: text))
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

    func change(blockchainType: BlockchainType) {
        self.blockchainType = blockchainType

        addressUriParser = AddressParserFactory.parser(blockchainType: blockchainType)
        addressParserChain = AddressParserFactory.parserChain(blockchainType: blockchainType)

        set(text: text)
        showContactsRelay.accept(showContacts)
    }

}

extension AddressService {

    enum State {
        case loading
        case empty
        case success(Address)
        case validationError(blockchainName: String?)
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
        case invalidAddress(blockchainName: String?)
    }

    enum Mode {
        case blockchainType
        case parsers(AddressUriParser, AddressParserChain)
    }

}

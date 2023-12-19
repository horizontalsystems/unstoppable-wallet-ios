import Foundation
import MarketKit
import RxCocoa
import RxSwift

protocol IAmountPublishService: AnyObject {
    var publishAmountRelay: BehaviorRelay<Decimal>? { get set }
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

    private let showUriErrorRelay = PublishRelay<Error>()

    private let showContactsRelay = PublishRelay<Bool>()
    var showContacts: Bool {
        guard let contactBookManager, let blockchainType else {
            return false
        }

        return !contactBookManager.contacts(blockchainUid: blockchainType.uid).isEmpty
    }

    private var text: String = ""

    let publishAmountRelay = BehaviorRelay<Decimal>(value: 0)

    weak var amountPublishService: IAmountPublishService? {
        didSet {
            amountPublishService?.publishAmountRelay = publishAmountRelay
        }
    }

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
            addressUriParser = AddressParserFactory.parser(blockchainType: blockchainType, tokenType: nil) // TODO: Check if tokenType is nesessary
            addressParserChain = blockchainType.flatMap { AddressParserFactory.parserChain(blockchainType: $0) }
        case let .parsers(uriParser, parserChain):
            addressUriParser = uriParser
            addressParserChain = parserChain
        }

        if let initialAddress {
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

        if let customErrorService {
            subscribe(disposeBag, customErrorService.errorObservable) { [weak self] in
                self?.sync(customError: $0)
            }
        }
    }

    private func sync(customError: Error?) {
        self.customError = customError
    }

    private func sync(address: Address?) {
        guard let address else {
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
        case let .fetchError(error): state = .fetchError(error)
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

    var showUriErrorObservable: Observable<Error> {
        showUriErrorRelay.asObservable().observeOn(scheduler)
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

        guard let addressParserChain else {
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
        do {
            let result = try addressUriParser.parse(url: text.trimmingCharacters(in: .whitespaces))
            if let amount = result.amount {
                publishAmountRelay.accept(amount)
            }
            set(text: result.address)
            return result.address
        } catch {
            switch error {
            case AddressUriParser.ParseError.noUri, AddressUriParser.ParseError.wrongUri:
                let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                set(text: text)
                return text
            default:
                showUriErrorRelay.accept(error)
                return ""
            }
        }
    }

    func change(blockchainType: BlockchainType) {
        self.blockchainType = blockchainType

        addressUriParser = AddressParserFactory.parser(blockchainType: blockchainType, tokenType: nil)
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

    enum UriError: Error {
        case invalidBlockchainType
        case invalidTokenType
    }

    enum Mode {
        case blockchainType
        case parsers(AddressUriParser, AddressParserChain)
    }
}

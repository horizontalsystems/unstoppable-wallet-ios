import Foundation
import MarketKit
import RxCocoa
import RxSwift

protocol IRecipientAddressService {
    var addressState: AddressService.State { get }
    var addressStateObservable: Observable<AddressService.State> { get }
    var recipientError: Error? { get }
    var recipientErrorObservable: Observable<Error?> { get }
    func set(address: Address?)
    func set(amount: Decimal)
}

open class RecipientAddressViewModel {
    private var queue = DispatchQueue(label: "\(AppConfig.label).resipient-view-model", qos: .userInitiated)

    private let disposeBag = DisposeBag()
    private let service: AddressService
    private let handlerDelegate: IRecipientAddressService? // for legacy handlers

    private let isSuccessRelay = BehaviorRelay<Bool>(value: false)
    private let isLoadingRelay = BehaviorRelay<Bool>(value: false)
    let cautionRelay = BehaviorRelay<Caution?>(value: nil)
    private let setTextRelay = BehaviorRelay<String?>(value: nil)
    private let showContactsRelay = BehaviorRelay<Bool>(value: false)
    private let showUriErrorRelay = PublishRelay<String>()

    private var editing = false

    init(service: AddressService, handlerDelegate: IRecipientAddressService?) {
        self.service = service
        self.handlerDelegate = handlerDelegate

        subscribeSerial(disposeBag, service.stateObservable) { [weak self] state in
            self?.serialSync(state: state)
        }

        subscribeSerial(disposeBag, service.customErrorObservable) { [weak self] _ in
            self?.serialSync()
        }
        subscribe(disposeBag, service.showContactsObservable) { [weak self] showContacts in
            self?.showContactsRelay.accept(showContacts)
        }
        subscribe(disposeBag, service.showUriErrorObservable) { [weak self] error in
            self?.showUriErrorRelay.accept(error.localizedDescription)
        }

        showContactsRelay.accept(service.showContacts)
        serialSync(state: service.state)
    }

    private func serialSync(state: AddressService.State? = nil, customError: Error? = nil) {
        queue.async { [weak self] in
            self?.sync(state: state, customError: customError)
        }
    }

    func sync(state: AddressService.State? = nil, customError: Error? = nil) {
        var state = state ?? service.state

        // force provide error if customError is exist
        if let customError = customError ?? service.customError {
            state = .fetchError(customError)
        }

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
        case let .validationError(blockchainName):
            cautionRelay.accept(editing ? nil : Caution(
                text: AddressService.AddressError.invalidAddress(blockchainName: blockchainName).smartDescription,
                type: .error
            )
            )
            isSuccessRelay.accept(false)
            isLoadingRelay.accept(false)

            handlerDelegate?.set(address: nil)
        case let .fetchError(error):
            cautionRelay.accept(Caution(text: error.convertedError.smartDescription, type: .error))
            isSuccessRelay.accept(false)
            isLoadingRelay.accept(false)

            handlerDelegate?.set(address: nil)
        case let .success(address):
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

    var showContactsDriver: Driver<Bool> {
        showContactsRelay.asDriver()
    }

    var showUriErrorDriver: Driver<String> {
        showUriErrorRelay.asDriver(onErrorJustReturn: "")
    }

    var contactBlockchainType: BlockchainType? {
        service.blockchainType
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
        serialSync(state: service.state)
    }
}

extension AddressService.AddressError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .invalidAddress(blockchainName):
            return ["send.error.invalid".localized, blockchainName, "send.error.address".localized]
                .compactMap { $0 }
                .joined(separator: " ")
        }
    }
}

extension AddressUriParser.ParseError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidBlockchainType:
            return "send.error.invalid_blockchain".localized
        case .invalidTokenType:
            return "send.error.invalid_token".localized
        case .wrongUri, .noUri:
            return "alert.cant_recognize".localized
        }
    }
}

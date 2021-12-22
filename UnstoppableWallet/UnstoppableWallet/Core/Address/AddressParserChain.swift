import Foundation
import RxSwift
import RxRelay
import RxCocoa
import EthereumKit

protocol IAddressParserItem: AnyObject {
    func handle(address: String) -> Single<Address>
    func isValid(address: String) -> Single<Bool>
}

class AddressParserChain {
    private var disposeBag = DisposeBag()

    private var stateRelay = PublishRelay<State>()
    private(set) var state: State {
        didSet {
            stateRelay.accept(state)
        }
    }

    private var handlers = [IAddressParserItem]()

    init(address: Address? = nil) {
        if let address = address {
            state = .success(address)
        } else {
            state = .empty
        }
    }

    private func sync(handlerStates: [HandlerState]) {
        let addresses = handlerStates.compactMap { $0.address }
        let errors = handlerStates.compactMap { $0.error }

        if let address = addresses.first {
            state = .success(address)
            return
        }

        if let error = errors.first {
            state = .fetchError(error)
            return
        }

        state = .empty
    }

    private func process(address: String, validHandlers: [IAddressParserItem]) {

        let singles: [Single<HandlerState>] = validHandlers
                .map { handler in
            handler.handle(address: address)
                    .map { address in HandlerState(address: address, error: nil) }
                    .catchError { error in Single.just(HandlerState(address: nil, error: error)) }
        }

        guard !validHandlers.isEmpty else {
            state = .validationError(ParserError.invalidAddress)
            return
        }

        Single.zip(singles)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] handlerStates in
                    self?.sync(handlerStates: handlerStates)
                })
                .disposed(by: disposeBag)

    }

    func handle(address: String?) {
        guard !(address ?? "").isEmpty, let address = address else {
            state = .empty
            return
        }

        let validHandlers: [Single<IAddressParserItem?>] = handlers
                .map { handler in
                    handler.isValid(address: address)
                        .map { [weak handler] isValid in
                            if isValid {
                                return handler
                            }
                            return nil
                        }
                        .catchErrorJustReturn(nil)
                }

        state = .loading
        disposeBag = DisposeBag()

        Single.zip(validHandlers)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onSuccess: { [weak self] validHandlers in
                    self?.process(address: address, validHandlers: validHandlers.compactMap { $0 })
                })
                .disposed(by: disposeBag)
    }

}

extension AddressParserChain {

    @discardableResult func append(handler: IAddressParserItem) -> Self {
        handlers.append(handler)
        return self
    }

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension AddressParserChain {

    private struct HandlerState {
        let address: Address?
        let error: Error?
    }

    enum State {
        case loading
        case empty
        case success(Address)
        case validationError(Error)
        case fetchError(Error)
    }

    enum ParserError: Error {
        case invalidAddress
    }

}

extension AddressParserChain.ParserError: LocalizedError {

    var errorDescription: String? {
        "send.error.invalid_address".localized
    }

}

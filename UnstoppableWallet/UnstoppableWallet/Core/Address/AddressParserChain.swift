import Foundation
import RxSwift
import RxRelay
import RxCocoa
import EthereumKit

protocol IAddressParserItem: AnyObject {
    var itemUpdatedObservable: Observable<()> { get }
    func handle(address: String) -> Single<Address>
    func isValid(address: String) -> Single<Bool>
}

extension IAddressParserItem {

    var itemUpdatedObservable: Observable<()> {
        .just(())
    }

}

class AddressParserChain {
    private let disposeBag = DisposeBag()
    private var handlers = [IAddressParserItem]()

    private var itemUpdatedRelay = PublishRelay<()>()

    private static func process(address: String, validHandlers: [IAddressParserItem]) -> Single<Address?> {
        guard !validHandlers.isEmpty else {
            return Single.error(ParserError.validationError)
        }

        let singles: [Single<HandlerState>] = validHandlers
                .map { handler in
                    handler
                        .handle(address: address)
                        .map { HandlerState(address: $0, error: nil) }
                        .catchError { Single.just(HandlerState(address: nil, error: $0)) }
        }

        return Single
            .zip(singles)
            .flatMap { handlerStates in
                if let address = handlerStates.first(where: { $0.address != nil })?.address {
                    return Single.just(address)
                }
                if let _ = handlerStates.first(where: { $0.error != nil })?.error {
                    return Single.error(ParserError.fetchError)
                }

                return Single.just(nil)
            }
    }

    private func register(handler: IAddressParserItem) {
        handlers.append(handler)

        subscribe(disposeBag, handler.itemUpdatedObservable) { [weak self] in self?.itemUpdatedRelay.accept(()) }
    }

}

extension AddressParserChain {

    var itemUpdatedObservable: Observable<()> {
        itemUpdatedRelay.asObservable()
    }

    @discardableResult func append(handler: IAddressParserItem) -> Self {
        register(handler: handler)
        return self
    }

    func handle(address: String?) -> Single<Address?> {
        guard !(address ?? "").isEmpty, let address = address else {
            return Single.just(nil)
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

        return Single
                .zip(validHandlers)
                .flatMap { (handlers: [IAddressParserItem?]) -> Single<Address?> in
                    let validHandlers: [IAddressParserItem] = handlers.compactMap { $0 }
                    return Self.process(address: address, validHandlers: validHandlers)
                }
    }

}

extension AddressParserChain {

    private struct HandlerState {
        let address: Address?
        let error: Error?
    }

    enum ParserError: Error {
        case validationError
        case fetchError
    }

}

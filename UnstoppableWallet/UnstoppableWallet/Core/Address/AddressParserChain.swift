import EvmKit
import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

protocol IAddressParserItem: AnyObject {
    var blockchainType: BlockchainType { get }
    func handle(address: String) -> Single<Address>
    func isValid(address: String) -> Single<Bool>
}

class AddressParserChain {
    private let disposeBag = DisposeBag()
    private var handlers = [IAddressParserItem]()

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
                if let error = handlerStates.first(where: { $0.error != nil })?.error {
                    return Single.error(ParserError.fetchError(error))
                }

                return Single.just(nil)
            }
    }
}

extension AddressParserChain {
    @discardableResult func append(handlers: [IAddressParserItem]) -> Self {
        self.handlers.append(contentsOf: handlers)
        return self
    }

    @discardableResult func append(handler: IAddressParserItem) -> Self {
        handlers.append(handler)
        return self
    }

    func handlers(address: String) -> Single<[IAddressParserItem]> {
        let singles = handlers.map { handler -> Single<IAddressParserItem?> in
            handler.isValid(address: address).map { $0 ? handler : nil }
        }

        return Single.zip(singles) { handlers in
            handlers.compactMap { $0 }
        }
    }

    func handle(address: String) -> Single<Address?> {
        handlers(address: address).flatMap { Self.process(address: address, validHandlers: $0) }
    }
}

extension AddressParserChain {
    private struct HandlerState {
        let address: Address?
        let error: Error?
    }

    enum ParserError: Error, LocalizedError {
        case validationError
        case fetchError(Error)

        public var errorDescription: String? {
            switch self {
            case .validationError: return "swap.advanced_settings.error.invalid_address".localized
            case let .fetchError(error): return "swap.advanced_settings.error.invalid_address".localized
            }
        }
    }
}

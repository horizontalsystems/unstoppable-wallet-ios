import Foundation
import MarketKit
import RxCocoa
import RxRelay
import RxSwift

protocol IAddressSecurityCheckerItem: AnyObject {
    func handle(address: Address) -> Single<AddressSecurityCheckerChain.SecurityIssue?>
}

class AddressSecurityCheckerChain {
    private let disposeBag = DisposeBag()
    private var handlers = [IAddressSecurityCheckerItem]()
}

extension AddressSecurityCheckerChain {
    @discardableResult func append(handlers: [IAddressSecurityCheckerItem]) -> Self {
        self.handlers.append(contentsOf: handlers)
        return self
    }

    @discardableResult func append(handler: IAddressSecurityCheckerItem) -> Self {
        handlers.append(handler)
        return self
    }

    func handle(address: Address) -> Single<[SecurityIssue]> {
        Single.zip(handlers.map { handler -> Single<SecurityIssue?> in
            handler.handle(address: address)
        })
        .map { $0.compactMap { $0 } }
    }
}

extension AddressSecurityCheckerChain {
    public enum SecurityIssue {
        case spam(transactionHash: String)
        case sanctioned(description: String)

        public var description: String? {
            switch self {
            case let .spam(transactionHash): return "Possibly phishing address. Transaction hash: \(transactionHash)"
            case let .sanctioned(description): return description
            }
        }
    }
}

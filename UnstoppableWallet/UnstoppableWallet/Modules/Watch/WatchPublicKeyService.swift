import Foundation
import RxSwift
import RxRelay
import HdWalletKit

class WatchPublicKeyService {
    private let disposeBag = DisposeBag()

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady {
        didSet {
            stateRelay.accept(state)
        }
    }

}

extension WatchPublicKeyService {

    func set(text: String) {
        if text.trimmingCharacters(in: .whitespaces).isEmpty {
            state = .notReady
        } else {
            state = .ready(text: text)
        }
    }

}

extension WatchPublicKeyService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func resolve() throws -> AccountType {
        switch state {
        case let .ready(text):
            let extendedKey = try HDExtendedKey(extendedKey: text)

            switch extendedKey {
            case .public:
                switch extendedKey.derivedType {
                case .account:
                    return .hdExtendedKey(key: extendedKey)
                default:
                    throw ResolveError.notSupportedDerivedType
                }
            default:
                throw ResolveError.nonPublicKey
            }
        case .notReady:
            throw ResolveError.notReady
        }
    }

}

extension WatchPublicKeyService {

    enum State {
        case ready(text: String)
        case notReady

        var watchEnabled: Bool {
            switch self {
            case .ready: return true
            case .notReady: return false
            }
        }
    }

    enum ResolveError: Error {
        case notReady
        case notSupportedDerivedType
        case nonPublicKey
    }

}

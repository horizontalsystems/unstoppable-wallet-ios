import Foundation
import RxSwift
import RxRelay

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
        if text.isEmpty {
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
            print(text)

            // todo

            throw ResolveError.invalidKey
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
        case invalidKey
    }

}

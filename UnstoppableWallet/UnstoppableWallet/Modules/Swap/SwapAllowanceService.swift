import Foundation
import UniswapKit
import RxSwift
import RxRelay

class SwapAllowanceService {

    private let stateRelay = PublishRelay<State>()
    private(set) var state: State = .notReady(errors: []) {
        didSet {
            stateRelay.accept(state)
        }
    }

    init() {

    }

}

extension SwapAllowanceService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

}

extension SwapAllowanceService {

    enum State {
        case loading
        case ready
        case notReady(errors: [Error])
    }

}

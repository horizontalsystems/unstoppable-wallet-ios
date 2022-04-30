import RxSwift
import RxRelay
import RxCocoa

class ProFeaturesYakAuthorizationService {
    private var disposeBag = DisposeBag()

    private let manager: ProFeaturesAuthorizationManager
    private let adapter: ProFeaturesAuthorizationAdapter

    private let stateRelay = BehaviorRelay<State>(value: .idle)
    private var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(manager: ProFeaturesAuthorizationManager, adapter: ProFeaturesAuthorizationAdapter) {
        self.manager = manager
        self.adapter = adapter
    }

    private func auth(accountData: [ProFeaturesAuthorizationManager.AccountData]) {
        guard let first = accountData.first else {
            return
        }

        state = .loading
        disposeBag = DisposeBag()

        adapter.message(address: first.address)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(
                        onNext: { [weak self] in self?.didReceive(message: $0) },
                        onError: { [weak self] in self?.didReceiveOnCheckAddress(error: $0) }
                )
                .disposed(by: disposeBag)
    }

    private func didReceive(message: String) {
        state = .received(message: message)
    }

    private func didReceiveOnCheckAddress(error: Error) {
        state = .failed(StateError.noYakNFT)
    }

}

extension ProFeaturesYakAuthorizationService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func authorize() {
        guard manager.sessionKey(type: .mountainYak) == nil else {
            return
        }

        let accountData = manager.allAccountData

    }
}

extension ProFeaturesYakAuthorizationService {

    enum StateError: Error {
        case noYakNFT
        case rejectSign
    }

    enum State {
        case idle
        case loading
        case receivedMessage(String)
        case receivedSessionKey(String)
        case failed(Error)
    }

}

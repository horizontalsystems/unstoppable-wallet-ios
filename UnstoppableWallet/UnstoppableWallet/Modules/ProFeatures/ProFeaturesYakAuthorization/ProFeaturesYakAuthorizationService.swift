import RxSwift
import RxRelay
import RxCocoa
import EthereumKit

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

    private func auth() {
        state = .loading
        disposeBag = DisposeBag()

        manager.nftHolder(type: .mountainYak)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(
                        onSuccess: { [weak self] in self?.didReceiveNtfHolder(accountData: $0) },
                        onError: { [weak self] in self?.didReceiveOnCheckAddress(error: $0) }
                )
                .disposed(by: disposeBag)
    }

    private func didReceiveNtfHolder(accountData: ProFeaturesAuthorizationManager.AccountData?) {
        guard let accountData = accountData else {
            state = .failed(StateError.noYakNFT)
            return
        }

        adapter.message(address: accountData.address.hex)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(
                        onSuccess: { [weak self] in self?.didReceive(accountData: accountData, message: $0) },
                        onError: { [weak self] in self?.didReceiveOnCheckAddress(error: $0) }
                )
                .disposed(by: disposeBag)

    }

    private func authenticate(accountData: ProFeaturesAuthorizationManager.AccountData, signature: String) {
        guard case let .receivedMessage(accountData, _) = state else {
            return
        }

        state = .loading
        disposeBag = DisposeBag()

        adapter.authenticate(address: accountData.address.hex, signature: signature)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(
                        onSuccess: { [weak self] in self?.didReceive(accountData: accountData, sessionKey: $0) },
                        onError: { [weak self] in self?.didReceiveOnAuthenticate(error: $0) }
                )
                .disposed(by: disposeBag)
    }

    private func didReceive(accountData: ProFeaturesAuthorizationManager.AccountData, message: String) {
        state = .receivedMessage(accountData, message)
    }

    private func didReceiveOnCheckAddress(error: Error) {
        print("Reject checking by \(error)")
        state = .failed(StateError.noYakNFT)
    }

    private func didReceive(accountData: ProFeaturesAuthorizationManager.AccountData, sessionKey: String) {
        manager.set(accountId: accountData.accountId, address: accountData.address.hex, sessionKey: sessionKey, type: .mountainYak)
        state = .receivedSessionKey(sessionKey)
    }

    private func didReceiveOnAuthenticate(error: Error) {
        print("Reject sign by \(error.smartDescription)")
        state = .failed(StateError.rejectSign)
    }

}

extension ProFeaturesYakAuthorizationService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func authenticate() {
//        guard manager.sessionKey(type: .mountainYak) == nil else {
//            return
//        }

        auth()
    }

    func activate() {
        guard case let .receivedMessage(accountData, message) = state,
              let data = message.data(using: .utf8),
              let signature = manager.sign(accountData: accountData, data: data) else {
            return
        }

        print("message: \(message) - \(String(data: data, encoding: .utf8))")
        print("address: \(accountData.address)")
        print("signature: \(signature)")

        authenticate(accountData: accountData, signature: signature)
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
        case receivedMessage(ProFeaturesAuthorizationManager.AccountData, String)
        case receivedSessionKey(String)
        case failed(Error)
    }

}

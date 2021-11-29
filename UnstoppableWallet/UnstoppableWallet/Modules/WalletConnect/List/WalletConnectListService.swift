import RxSwift
import RxRelay
import EthereumKit

class WalletConnectListService {
    private let sessionManager: WalletConnectSessionManager

    private var sessionKiller: WalletConnectSessionKiller?
    private var disposeBag = DisposeBag()

    private let sessionKillingRelay = PublishRelay<SessionKillingState>()

    init(sessionManager: WalletConnectSessionManager) {
        self.sessionManager = sessionManager
    }

    private func items(sessions: [WalletConnectSession]) -> [Item] {
        Chain.allCases.compactMap { chain in
            let sessions = sessions.filter { $0.chainId == chain.rawValue }

            guard !sessions.isEmpty else {
                return nil
            }

            return Item(chain: chain, sessions: sessions)
        }
    }

    private func onUpdateSessionKiller(state: WalletConnectSessionKiller.State) {
        switch state {
        case .killed: finishSessionKill()
        case .failed: finishSessionKill(successful: false)
        default: ()
        }
    }

    private func finishSessionKill(successful: Bool = true) {
        if let killer = sessionKiller {
            sessionManager.deleteSession(peerId: killer.peerId)
        }

        sessionKiller = nil             //deinit session killer and clean disposeBag
        disposeBag = DisposeBag()

        sessionKillingRelay.accept(successful ? .completed : .removedOnly)
    }

}

extension WalletConnectListService {

    var items: [Item] {
        items(sessions: sessionManager.sessions)
    }

    var sessionCount: Int {
        sessionManager.sessions.count
    }

    var itemsObservable: Observable<[Item]> {
        sessionManager.sessionsObservable.map { [weak self] in
            self?.items(sessions: $0) ?? []
        }
    }

    var sessionKillingObservable: Observable<SessionKillingState> {
        sessionKillingRelay.asObservable()
    }

    func kill(session: WalletConnectSession) {
        sessionKillingRelay.accept(.processing)

        let sessionKiller = WalletConnectSessionKiller(session: session)
        let forceTimer = Observable.just(()).delay(.seconds(5), scheduler: ConcurrentDispatchQueueScheduler(qos: .userInitiated))

        subscribe(disposeBag, forceTimer) { [weak self] in self?.finishSessionKill(successful: false) }
        subscribe(disposeBag, sessionKiller.stateObservable) { [weak self] in
            self?.onUpdateSessionKiller(state: $0)
        }

        sessionKiller.kill()
        self.sessionKiller = sessionKiller
    }

}

extension WalletConnectListService {

    enum SessionKillingState {
        case processing
        case completed
        case removedOnly
    }

    enum Chain: Int, CaseIterable {
        case ethereum = 1
        case binanceSmartChain = 56
        case ropsten = 3
        case rinkeby = 4
        case kovan = 42
        case goerli = 5
    }

    struct Item {
        let chain: Chain
        let sessions: [WalletConnectSession]
    }

}

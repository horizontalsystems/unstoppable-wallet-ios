import RxSwift

class WalletConnectListService {
    private let sessionManager: WalletConnectSessionManager

    init(sessionManager: WalletConnectSessionManager) {
        self.sessionManager = sessionManager
    }

}

extension WalletConnectListService {

    var sessions: [WalletConnectSession] {
        sessionManager.sessions
    }

    var sessionsObservable: Observable<[WalletConnectSession]> {
        sessionManager.sessionsObservable
    }

}

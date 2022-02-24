import WalletConnectV1
import RxRelay
import RxSwift

class WalletConnectSessionKiller {
    private let session: WalletConnectSession
    private let interactor: WalletConnectInteractor

    private let stateRelay: PublishRelay<State> = PublishRelay<State>()
    private(set) var state: State = .notConnected {
        didSet {
            stateRelay.accept(state)
        }
    }

    var peerId: String { session.peerId }

    init(session: WalletConnectSession) {
        self.session = session

        interactor = WalletConnectInteractor(session: session.session, remotePeerId: session.peerId)
        interactor.delegate = self
    }

}

extension WalletConnectSessionKiller {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    func kill() {
        guard interactor.state == .disconnected else {
            return
        }

        interactor.connect()
    }

}

extension WalletConnectSessionKiller: IWalletConnectInteractorDelegate {

    func didUpdate(state: WalletConnectInteractor.State) {
        switch state {
        case .connected: interactor.killSession()
        case .connecting: self.state = .processing
        case .disconnected: ()
        }
    }

    func didKillSession() {
        state = .killed
    }

    func didReceive(error: Error) {
        state = .failed(error: error)
    }

}

extension WalletConnectSessionKiller {

    enum State {
        case notConnected
        case processing
        case killed
        case failed(error: Error)
    }

}

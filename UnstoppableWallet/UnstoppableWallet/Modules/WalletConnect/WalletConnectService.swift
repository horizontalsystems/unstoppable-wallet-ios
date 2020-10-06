import EthereumKit
import WalletConnect
import RxSwift

class WalletConnectService {
    private var ethereumKit: Kit?
    private var interactor: WalletConnectInteractor?
    private(set) var peerMeta: WCPeerMeta?

    private var stateSubject = PublishSubject<State>()

    private(set) var state: State = .idle {
        didSet {
            stateSubject.onNext(state)
        }
    }

    init(ethereumKitManager: EthereumKitManager) {
        ethereumKit = ethereumKitManager.ethereumKit

        if let storeItem = WCSessionStore.allSessions.first?.value {
            peerMeta = storeItem.peerMeta

            interactor = WalletConnectInteractor(session: storeItem.session)
            interactor?.delegate = self
            interactor?.connect()

            state = .connecting
        }
    }

}

extension WalletConnectService {

    var stateObservable: Observable<State> {
        stateSubject.asObservable()
    }

    var isEthereumKitReady: Bool {
        ethereumKit != nil
    }

    func connect(uri: String) throws {
        interactor = try WalletConnectInteractor(uri: uri)
        interactor?.delegate = self
        interactor?.connect()

        state = .connecting
    }

    func approveSession() {
        guard let ethereumKit = ethereumKit, let interactor = interactor else {
            return
        }

        interactor.approveSession(address: ethereumKit.address.eip55, chainId: 1) // todo: get chainId from kit

        state = .ready
    }

    func rejectSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.rejectSession()

        state = .rejected
    }

}

extension WalletConnectService: IWalletConnectInteractorDelegate {

    func didConnect() {
    }

    func didRequestSession(peerMeta: WCPeerMeta) {
        self.peerMeta = peerMeta

        state = .waitingForApproveSession
    }

}

extension WalletConnectService {

    enum State {
        case idle
        case connecting
        case waitingForApproveSession
        case ready
        case rejected
    }

}

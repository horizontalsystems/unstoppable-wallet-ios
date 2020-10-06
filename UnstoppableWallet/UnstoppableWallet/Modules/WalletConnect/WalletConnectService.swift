import EthereumKit
import WalletConnect
import RxSwift

class WalletConnectService {
    private var ethereumKit: Kit?
    private var interactor: WalletConnectInteractor?
    private var peerData: PeerData?

    private var stateSubject = PublishSubject<State>()

    private(set) var state: State = .idle {
        didSet {
            stateSubject.onNext(state)
        }
    }

    init(ethereumKitManager: EthereumKitManager) {
        ethereumKit = ethereumKitManager.ethereumKit

        if let storeItem = WCSessionStore.allSessions.first?.value {
            peerData = PeerData(id: storeItem.peerId, meta: storeItem.peerMeta)

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

    var peerMeta: WCPeerMeta? {
        peerData?.meta
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

        if let peerData = peerData {
            WCSessionStore.store(interactor.session, peerId: peerData.id, peerMeta: peerData.meta)
        }

        state = .ready
    }

    func rejectSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.rejectSession()

        state = .rejected
    }

    func killSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.killSession()
    }

}

extension WalletConnectService: IWalletConnectInteractorDelegate {

    func didConnect() {
        if peerData != nil {
            state = .ready
        }
    }

    func didRequestSession(peerId: String, peerMeta: WCPeerMeta) {
        peerData = PeerData(id: peerId, meta: peerMeta)

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

    struct PeerData {
        let id: String
        let meta: WCPeerMeta
    }

}

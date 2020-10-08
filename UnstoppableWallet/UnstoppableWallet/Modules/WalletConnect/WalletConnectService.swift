import EthereumKit
import WalletConnect
import RxSwift
import RxRelay

class WalletConnectService {
    private var ethereumKit: Kit?
    private var interactor: WalletConnectInteractor?
    private var remotePeerData: PeerData?

    private var stateRelay = PublishRelay<State>()
    private var requestRelay = PublishRelay<Int>()

    private var pendingRequests = [Request]()

    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(ethereumKitManager: EthereumKitManager) {
        ethereumKit = ethereumKitManager.ethereumKit

        if let storeItem = WCSessionStore.allSessions.first?.value {
            remotePeerData = PeerData(id: storeItem.peerId, meta: storeItem.peerMeta)

            interactor = WalletConnectInteractor(session: storeItem.session, remotePeerId: storeItem.peerId)
            interactor?.delegate = self
            interactor?.connect()

            state = .connecting
        }
    }

}

extension WalletConnectService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var requestObservable: Observable<Int> {
        requestRelay.asObservable()
    }

    var isEthereumKitReady: Bool {
        ethereumKit != nil
    }

    var remotePeerMeta: WCPeerMeta? {
        remotePeerData?.meta
    }

    var ethereumCoin: Coin? {
        App.shared.appConfigProvider.defaultCoins.first(where: { $0.type == .ethereum })
    }

    func request(id: Int) -> Request? {
        pendingRequests.first { $0.id == id }
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

        interactor.approveSession(address: ethereumKit.address.eip55, chainId: ethereumKit.networkType.chainId)

        if let peerData = remotePeerData {
            WCSessionStore.store(interactor.session, peerId: peerData.id, peerMeta: peerData.meta)
        }

        state = .ready
    }

    func rejectSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.rejectSession()

        state = .completed
    }

    func approveRequest(id: Int) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == id }) else {
            return
        }

        let request = pendingRequests.remove(at: index)

        switch request.type {
        case .sendEthereumTransaction(let transaction):
            // todo
            interactor?.rejectRequest(id: id, message: "Not implemented yet")
        case .signEthereumTransaction(let transaction):
            // todo
            interactor?.rejectRequest(id: id, message: "Not implemented yet")
        }
    }

    func rejectRequest(id: Int) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == id }) else {
            return
        }

        pendingRequests.remove(at: index)

        interactor?.rejectRequest(id: id, message: "Rejected by user")
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
        if remotePeerData != nil {
            state = .ready
        }
    }

    func didRequestSession(peerId: String, peerMeta: WCPeerMeta) {
        remotePeerData = PeerData(id: peerId, meta: peerMeta)

        state = .waitingForApproveSession
    }

    func didKillSession() {
        WCSessionStore.clearAll()

        state = .completed
    }

    func didRequestEthereumTransaction(id: Int, event: WCEvent, transaction: WCEthereumTransaction) {
        var requestType: Request.RequestType?

        switch event {
        case .ethSendTransaction: requestType = .sendEthereumTransaction(transaction: transaction)
        case .ethSignTransaction: requestType = .signEthereumTransaction(transaction: transaction)
        default: ()
        }

        guard let type = requestType else {
            interactor?.rejectRequest(id: id, message: "Not supported yet")
            return
        }

        let request = Request(id: id, type: type)

        pendingRequests.append(request)

        requestRelay.accept(request.id)
    }

}

extension WalletConnectService {

    enum State {
        case idle
        case connecting
        case waitingForApproveSession
        case ready
        case completed
    }

    struct PeerData {
        let id: String
        let meta: WCPeerMeta
    }

    struct Request {
        let id: Int
        let type: RequestType

        enum RequestType {
            case sendEthereumTransaction(transaction: WCEthereumTransaction)
            case signEthereumTransaction(transaction: WCEthereumTransaction)
        }
    }

}

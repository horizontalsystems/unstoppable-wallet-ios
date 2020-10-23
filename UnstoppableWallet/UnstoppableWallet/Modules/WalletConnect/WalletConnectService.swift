import EthereumKit
import WalletConnect
import RxSwift
import RxRelay
import CurrencyKit
import BigInt

class WalletConnectService {
    private var ethereumKit: EthereumKit.Kit?
    private let sessionStore: WalletConnectSessionStore

    private let disposeBag = DisposeBag()

    private var interactor: WalletConnectInteractor?
    private var remotePeerData: PeerData?

    private var stateRelay = PublishRelay<State>()
    private var connectionStateRelay = PublishRelay<WalletConnectInteractor.State>()
    private var requestRelay = PublishRelay<WalletConnectRequest>()

    private var pendingRequests = [WalletConnectRequest]()

    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    var connectionState: WalletConnectInteractor.State {
        interactor?.state ?? .disconnected
    }

    init(ethereumKitManager: EthereumKitManager, sessionStore: WalletConnectSessionStore) {
        ethereumKit = ethereumKitManager.ethereumKit
        self.sessionStore = sessionStore

        if let storeItem = sessionStore.storedItem {
            remotePeerData = PeerData(id: storeItem.peerId, meta: storeItem.peerMeta)

            interactor = WalletConnectInteractor(session: storeItem.session, remotePeerId: storeItem.peerId)
            interactor?.delegate = self
            interactor?.connect()

            state = .ready
        }
    }

    private func handleRequest(id: Int, requestResolver: () throws -> WalletConnectRequest) {
        do {
            let request = try requestResolver()

            // todo: handle several requests in a row

            pendingRequests.append(request)
            requestRelay.accept(request)
        } catch {
            interactor?.rejectRequest(id: id, message: error.smartDescription)
        }
    }

    private func converted(result: Any) -> String? {
        if let dataResult = result as? Data {
            return dataResult.toHexString()
        }

        return nil
    }

}

extension WalletConnectService {

    var stateObservable: Observable<State> {
        stateRelay.asObservable()
    }

    var connectionStateObservable: Observable<WalletConnectInteractor.State> {
        connectionStateRelay.asObservable()
    }

    var requestObservable: Observable<WalletConnectRequest> {
        requestRelay.asObservable()
    }

    var isEthereumKitReady: Bool {
        ethereumKit != nil
    }

    var remotePeerMeta: WCPeerMeta? {
        remotePeerData?.meta
    }

    func connect(uri: String) throws {
        interactor = try WalletConnectInteractor(uri: uri)
        interactor?.delegate = self
        interactor?.connect()
    }

    func approveSession() {
        guard let ethereumKit = ethereumKit, let interactor = interactor else {
            return
        }

        interactor.approveSession(address: ethereumKit.address.eip55, chainId: ethereumKit.networkType.chainId)

        if let peerData = remotePeerData {
            sessionStore.store(session: interactor.session, peerId: peerData.id, peerMeta: peerData.meta)
        }

        state = .ready
    }

    func rejectSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.rejectSession()

        state = .killed
    }

    func approveRequest(id: Int, result: Any) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == id }) else {
            return
        }

        pendingRequests.remove(at: index)

        if let convertedResult = converted(result: result) {
            interactor?.approveRequest(id: id, result: convertedResult)
        }

        // todo: handle next pending request
    }

    func rejectRequest(id: Int) {
        guard let index = pendingRequests.firstIndex(where: { $0.id == id }) else {
            return
        }

        pendingRequests.remove(at: index)
        interactor?.rejectRequest(id: id, message: "Rejected by user")

        // todo: handle next pending request
    }

    func killSession() {
        guard let interactor = interactor else {
            return
        }

        interactor.killSession()
    }

}

extension WalletConnectService: IWalletConnectInteractorDelegate {

    func didUpdate(state: WalletConnectInteractor.State) {
        connectionStateRelay.accept(state)
    }

    func didRequestSession(peerId: String, peerMeta: WCPeerMeta) {
        remotePeerData = PeerData(id: peerId, meta: peerMeta)

        state = .waitingForApproveSession
    }

    func didKillSession() {
        sessionStore.clear()

        state = .killed
    }

    func didRequestSendEthereumTransaction(id: Int, transaction: WCEthereumTransaction) {
        handleRequest(id: id) {
            try WalletConnectSendEthereumTransactionRequest(id: id, transaction: transaction)
        }
    }

}

extension WalletConnectService {

    enum State {
        case idle
        case waitingForApproveSession
        case ready
        case killed
    }

    struct PeerData {
        let id: String
        let meta: WCPeerMeta
    }

}

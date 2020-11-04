import EthereumKit
import WalletConnect
import RxSwift
import RxRelay
import CurrencyKit
import BigInt
import HsToolKit

class WalletConnectService {
    private var ethereumKit: EthereumKit.Kit?
    private let sessionStore: WalletConnectSessionStore
    private let reachabilityManager: IReachabilityManager

    private let disposeBag = DisposeBag()

    private var interactor: WalletConnectInteractor?
    private var remotePeerData: PeerData?

    private var stateRelay = PublishRelay<State>()
    private var connectionStateRelay = PublishRelay<WalletConnectInteractor.State>()
    private var requestRelay = PublishRelay<WalletConnectRequest>()

    private var pendingRequests = [Int: WalletConnectRequest]()
    private var requestIsProcessing = false

    private let queue = DispatchQueue(label: "io.horizontalsystems.unstoppable.wallet-connect-service", qos: .userInitiated)

    private(set) var state: State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    var connectionState: WalletConnectInteractor.State {
        interactor?.state ?? .disconnected
    }

    init(ethereumKitManager: EthereumKitManager, sessionStore: WalletConnectSessionStore, reachabilityManager: IReachabilityManager) {
        ethereumKit = ethereumKitManager.ethereumKit
        self.sessionStore = sessionStore
        self.reachabilityManager = reachabilityManager

        if let storeItem = sessionStore.storedItem {
            remotePeerData = PeerData(id: storeItem.peerId, meta: storeItem.peerMeta)

            interactor = WalletConnectInteractor(session: storeItem.session, remotePeerId: storeItem.peerId)
            interactor?.delegate = self
            interactor?.connect()

            state = .ready
        }

        reachabilityManager.reachabilityObservable
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onNext: { [weak self] reachable in
                    if reachable {
                        self?.interactor?.connect()
                    }
                })
                .disposed(by: disposeBag)
    }

    private func handleRequest(id: Int, requestResolver: () throws -> WalletConnectRequest) {
        do {
            let request = try requestResolver()
            pendingRequests[id] = request
            processNextRequest()
        } catch {
            interactor?.rejectRequest(id: id, message: error.smartDescription)
        }
    }

    private func processNextRequest() {
        guard !requestIsProcessing else {
            return
        }

        guard let nextRequest = pendingRequests.values.first else {
            return
        }

        requestRelay.accept(nextRequest)
        requestIsProcessing = true
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
        queue.async {
            if let request = self.pendingRequests.removeValue(forKey: id), let convertedResult = request.convert(result: result) {
                self.interactor?.approveRequest(id: id, result: convertedResult)
            }

            self.requestIsProcessing = false
            self.processNextRequest()
        }
    }

    func rejectRequest(id: Int) {
        queue.async {
            self.pendingRequests.removeValue(forKey: id)

            self.interactor?.rejectRequest(id: id, message: "Rejected by user")

            self.requestIsProcessing = false
            self.processNextRequest()
        }
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
        queue.async {
            self.handleRequest(id: id) {
                try WalletConnectSendEthereumTransactionRequest(id: id, transaction: transaction)
            }
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

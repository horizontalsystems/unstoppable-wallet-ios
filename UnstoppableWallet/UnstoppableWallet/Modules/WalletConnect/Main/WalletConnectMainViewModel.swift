import RxSwift
import RxRelay
import RxCocoa
import WalletConnectV1

class WalletConnectMainViewModel {
    private let service: WalletConnectService

    private let disposeBag = DisposeBag()

    private let showErrorRelay = PublishRelay<Error>()
    private let showSuccessRelay = PublishRelay<()>()
    private let connectingRelay = BehaviorRelay<Bool>(value: false)
    private let cancelVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let connectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let reconnectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let disconnectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
    private let closeVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let signedTransactionsVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let peerMetaRelay = BehaviorRelay<PeerMetaViewItem?>(value: nil)
    private let hintRelay = BehaviorRelay<String?>(value: nil)
    private let statusRelay = BehaviorRelay<Status?>(value: nil)

    private let openRequestRelay = PublishRelay<WalletConnectRequest>()
    private let finishRelay = PublishRelay<Void>()

    init(service: WalletConnectService) {
        self.service = service

        subscribe(disposeBag, service.errorObservable) { [weak self] in self?.showErrorRelay.accept($0) }
        subscribe(disposeBag, service.stateObservable) { [weak self] in self?.sync(state: $0) }
        subscribe(disposeBag, service.connectionStateObservable) { [weak self] in self?.sync(connectionState: $0) }
        subscribe(disposeBag, service.requestObservable) { [weak self] in self?.openRequestRelay.accept($0) }

        sync()
    }

    private func sync(state: WalletConnectService.State? = nil, connectionState: WalletConnectInteractor.State? = nil) {
        let state = state ?? service.state
        let connectionState = connectionState ?? service.connectionState

        print("\(state) --- \(connectionState)")

        guard state != .killed else {
            showSuccessRelay.accept(())
            finishRelay.accept(())
            return
        }

        connectingRelay.accept(service.state == .idle)
        cancelVisibleRelay.accept(state != .ready)
        connectButtonRelay.accept(state == .waitingForApproveSession ? (connectionState == .connected ? .enabled : .hidden) : .hidden)
        disconnectButtonRelay.accept(state == .ready ? (connectionState == .connected ? .enabled : .hidden) : .hidden)

        let stateForReconnectButton = state == .waitingForApproveSession || state == .ready
        reconnectButtonRelay.accept(stateForReconnectButton ? (connectionState == .disconnected ? .enabled : .hidden) : .hidden)
        closeVisibleRelay.accept(state == .ready)

//        signedTransactionsVisibleRelay.accept(state == .ready)

        peerMetaRelay.accept(service.remotePeerMeta.map { viewItem(peerMeta: $0) })
        hintRelay.accept(hint(state: state, connection: connectionState))
        statusRelay.accept(status(connectionState: connectionState))
    }

    private func hint(state: WalletConnectService.State, connection: WalletConnectInteractor.State) -> String? {
        switch connection {
        case .disconnected:
            if state == .waitingForApproveSession || state == .ready {
                return "wallet_connect.no_connection".localized
            }
        case .connecting: return nil
        case .connected: ()
        }

        switch state {
        case .invalid(let error):
            return error.smartDescription
        case .waitingForApproveSession:
            return "wallet_connect.connect_description".localized
        case .ready:
            return "wallet_connect.usage_description".localized
        default:
            return nil
        }
    }

    private func status(connectionState: WalletConnectInteractor.State) -> Status? {
        guard service.remotePeerMeta != nil else {
            return nil
        }

        switch connectionState {
        case .connecting:
            return .connecting
        case .connected:
            return .online
        case .disconnected:
            return .offline
        }
    }

    private func viewItem(peerMeta: WCPeerMeta) -> PeerMetaViewItem {
        PeerMetaViewItem(
                name: peerMeta.name,
                url: peerMeta.url,
                description: peerMeta.description,
                icon: peerMeta.icons.last
        )
    }

}

extension WalletConnectMainViewModel {

    var showErrorSignal: Signal<Error> {
        showErrorRelay.asSignal()
    }

    var showSuccessSignal: Signal<()> {
        showSuccessRelay.asSignal()
    }

    var connectingDriver: Driver<Bool> {
        connectingRelay.asDriver()
    }

    var cancelVisibleDriver: Driver<Bool> {
        cancelVisibleRelay.asDriver()
    }

    var connectButtonDriver: Driver<ButtonState> {
        connectButtonRelay.asDriver()
    }

    var reconnectButtonDriver: Driver<ButtonState> {
        reconnectButtonRelay.asDriver()
    }

    var disconnectButtonDriver: Driver<ButtonState> {
        disconnectButtonRelay.asDriver()
    }

    var closeVisibleDriver: Driver<Bool> {
        closeVisibleRelay.asDriver()
    }

    var signedTransactionsVisibleDriver: Driver<Bool> {
        signedTransactionsVisibleRelay.asDriver()
    }

    var peerMetaDriver: Driver<PeerMetaViewItem?> {
        peerMetaRelay.asDriver()
    }

    var hintDriver: Driver<String?> {
        hintRelay.asDriver()
    }

    var statusDriver: Driver<Status?> {
        statusRelay.asDriver()
    }

    var openRequestSignal: Signal<WalletConnectRequest> {
        openRequestRelay.asSignal()
    }

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func cancel() {
        if service.connectionState == .connected && service.state == .waitingForApproveSession {
            service.rejectSession()
        } else {
            finishRelay.accept(())
        }
    }

    func reconnect() {
        service.reconnect()
    }

    func connect() {
        service.approveSession()
    }

    func reject() {
        service.rejectSession()
    }

    func disconnect() {
        service.killSession()
    }

    func close() {
        finishRelay.accept(())
    }

    func approveRequest(id: Int, result: Any) {
        service.approveRequest(id: id, result: result)
    }

    func rejectRequest(id: Int) {
        service.rejectRequest(id: id)
    }

}

extension WalletConnectMainViewModel {

    struct PeerMetaViewItem {
        let name: String
        let url: String
        let description: String
        let icon: String?
    }

    enum Status {
        case connecting
        case online
        case offline

        var color: UIColor {
            switch self {
            case .connecting: return .themeLeah
            case .offline: return .themeLucian
            case .online: return .themeRemus
            }
        }

        var title: String {
            switch self {
            case .connecting: return "connecting".localized
            case .offline: return "offline".localized
            case .online: return "online".localized
            }
        }
    }

}

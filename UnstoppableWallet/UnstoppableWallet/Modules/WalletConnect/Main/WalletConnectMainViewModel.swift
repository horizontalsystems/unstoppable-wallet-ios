import RxSwift
import RxRelay
import RxCocoa
import WalletConnect

class WalletConnectMainViewModel {
    private let service: WalletConnectService

    private let disposeBag = DisposeBag()

    private let connectingRelay = BehaviorRelay<Bool>(value: false)
    private let cancelVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let connectButtonRelay = BehaviorRelay<ButtonState>(value: .hidden)
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

        service.stateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.sync(state: state)
                })
                .disposed(by: disposeBag)

        service.connectionStateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.sync(connectionState: state)
                })
                .disposed(by: disposeBag)

        service.requestObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] request in
                    self?.openRequestRelay.accept(request)
                })
                .disposed(by: disposeBag)

        sync()
    }

    private func sync(state: WalletConnectService.State? = nil, connectionState: WalletConnectInteractor.State? = nil) {
        let state = state ?? service.state
        let connectionState = connectionState ?? service.connectionState

        print("\(state) --- \(connectionState)")

        guard state != .killed else {
            finishRelay.accept(())
            return
        }

        connectingRelay.accept(service.state == .idle)
        cancelVisibleRelay.accept(state != .ready)
        connectButtonRelay.accept(state == .waitingForApproveSession ? (connectionState == .connected ? .enabled : .disabled) : .hidden)
        disconnectButtonRelay.accept(state == .ready ? (connectionState == .connected ? .enabled : .disabled) : .hidden)
        closeVisibleRelay.accept(state == .ready)

//        signedTransactionsVisibleRelay.accept(state == .ready)

        peerMetaRelay.accept(service.remotePeerMeta.map { viewItem(peerMeta: $0) })
        hintRelay.accept(hint(state: state))
        statusRelay.accept(status(connectionState: connectionState))
    }

    private func hint(state: WalletConnectService.State) -> String? {
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

    var connectingDriver: Driver<Bool> {
        connectingRelay.asDriver()
    }

    var cancelVisibleDriver: Driver<Bool> {
        cancelVisibleRelay.asDriver()
    }

    var connectButtonDriver: Driver<ButtonState> {
        connectButtonRelay.asDriver()
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

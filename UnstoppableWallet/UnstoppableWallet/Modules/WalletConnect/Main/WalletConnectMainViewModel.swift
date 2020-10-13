import RxSwift
import RxRelay
import RxCocoa
import WalletConnect

class WalletConnectMainViewModel {
    private let service: WalletConnectService

    private let disposeBag = DisposeBag()

    private let connectingRelay = BehaviorRelay<Bool>(value: false)
    private let cancelVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let approveAndRejectVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let disconnectVisibleRelay = BehaviorRelay<Bool>(value: false)
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

        service.requestObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] request in
                    self?.openRequestRelay.accept(request)
                })
                .disposed(by: disposeBag)

        sync()
    }

    private func sync(state: WalletConnectService.State? = nil) {
        let state = state ?? service.state

        guard state != .completed else {
            finishRelay.accept(())
            return
        }

        connectingRelay.accept(state == .connecting && service.remotePeerMeta == nil)
        cancelVisibleRelay.accept(state == .connecting)
        disconnectVisibleRelay.accept(state == .ready)
        closeVisibleRelay.accept(state == .ready)
        approveAndRejectVisibleRelay.accept(state == .waitingForApproveSession)
        signedTransactionsVisibleRelay.accept(state == .ready)

        peerMetaRelay.accept(service.remotePeerMeta.map { viewItem(peerMeta: $0) })
        hintRelay.accept(hint(state: state))
        statusRelay.accept(status(state: state))
    }

    private func hint(state: WalletConnectService.State) -> String? {
        switch state {
        case .waitingForApproveSession:
            return "waiting"
        case .ready:
            return "ready"
        default:
            return nil
        }
    }

    private func status(state: WalletConnectService.State) -> Status? {
        switch state {
        case .connecting:
            return .connecting
        case .ready:
            return .online
        default:
            return nil
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

    var approveAndRejectVisibleDriver: Driver<Bool> {
        approveAndRejectVisibleRelay.asDriver()
    }

    var disconnectVisibleDriver: Driver<Bool> {
        disconnectVisibleRelay.asDriver()
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

    func approve() {
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

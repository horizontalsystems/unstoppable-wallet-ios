import RxSwift
import RxRelay
import RxCocoa
import WalletConnect

class WalletConnectMainPresenter {
    private let service: WalletConnectService

    private let disposeBag = DisposeBag()

    private let connectingRelay = BehaviorRelay<Bool>(value: false)
    private let cancelVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let approveAndRejectVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let disconnectVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let signedTransactionsVisibleRelay = BehaviorRelay<Bool>(value: false)
    private let peerMetaRelay = BehaviorRelay<PeerMetaViewItem?>(value: nil)
    private let hintRelay = BehaviorRelay<String?>(value: nil)
    private let statusRelay = BehaviorRelay<Status?>(value: nil)

    private let finishRelay = PublishRelay<Void>()

    init(service: WalletConnectService) {
        self.service = service

        service.stateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.sync(state: state)
                })
                .disposed(by: disposeBag)

        sync()
    }

    private func sync(state: WalletConnectService.State? = nil) {
        let state = state ?? service.state

        connectingRelay.accept(state == .connecting && service.peerMeta == nil)
        cancelVisibleRelay.accept(state == .connecting)
        disconnectVisibleRelay.accept(state == .ready)
        approveAndRejectVisibleRelay.accept(state == .waitingForApproveSession)
        signedTransactionsVisibleRelay.accept(state == .ready)

        peerMetaRelay.accept(service.peerMeta.map { viewItem(peerMeta: $0) })
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
        PeerMetaViewItem(name: peerMeta.name)
    }

}

extension WalletConnectMainPresenter {

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

    var finishSignal: Signal<Void> {
        finishRelay.asSignal()
    }

    func approve() {
        service.approveSession()
    }

    func reject() {
        service.rejectSession()
        finishRelay.accept(())
    }

    func disconnect() {
    }

}

extension WalletConnectMainPresenter {

    struct PeerMetaViewItem {
        let name: String
    }

    enum Status {
        case connecting
        case online
        case offline
    }

}

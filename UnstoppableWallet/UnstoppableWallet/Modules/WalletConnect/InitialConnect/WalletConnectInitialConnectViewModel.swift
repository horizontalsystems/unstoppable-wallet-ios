import RxSwift
import RxRelay
import RxCocoa
import WalletConnect

class WalletConnectInitialConnectViewModel {
    private let service: WalletConnectInitialConnectService

    private let disposeBag = DisposeBag()

    private let connectingRelay = BehaviorRelay<Bool>(value: true)
    private let peerMetaRelay = BehaviorRelay<PeerMetaViewItem?>(value: nil)
    private let approvedRelay = PublishRelay<WCPeerMeta>()
    private let rejectedRelay = PublishRelay<Void>()

    init(service: WalletConnectInitialConnectService) {
        self.service = service

        service.stateObservable
                .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInitiated))
                .subscribe(onNext: { [weak self] state in
                    self?.syncState(state: state)
                })
                .disposed(by: disposeBag)

        syncState()
    }

    private func syncState(state: WalletConnectInitialConnectService.State? = nil) {
        let state = state ?? service.state

        if case .approved(let peerMeta) = state {
            approvedRelay.accept(peerMeta)
            return
        }

        if case .rejected = state {
            rejectedRelay.accept(())
            return
        }

        if case .connecting = state {
            connectingRelay.accept(true)
        } else {
            connectingRelay.accept(false)
        }

        if case .waitingForApproveSession(let peerMeta) = state {
            peerMetaRelay.accept(viewItem(peerMeta: peerMeta))
        } else {
            peerMetaRelay.accept(nil)
        }
    }

    private func viewItem(peerMeta: WCPeerMeta) -> PeerMetaViewItem {
        PeerMetaViewItem(name: peerMeta.name)
    }
}

extension WalletConnectInitialConnectViewModel {

    var connectingDriver: Driver<Bool> {
        connectingRelay.asDriver()
    }

    var peerMetaDriver: Driver<PeerMetaViewItem?> {
        peerMetaRelay.asDriver()
    }

    var approvedSignal: Signal<WCPeerMeta> {
        approvedRelay.asSignal()
    }

    var rejectedSignal: Signal<Void> {
        rejectedRelay.asSignal()
    }

    func approve() {
        service.approveSession()
    }

    func reject() {
        service.rejectSession()
    }

}

extension WalletConnectInitialConnectViewModel {

    struct PeerMetaViewItem {
        let name: String
    }

}

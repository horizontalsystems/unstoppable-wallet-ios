import EthereumKit
import WalletConnect
import RxSwift

class WalletConnectInitialConnectService {
    private let interactor: WalletConnectInteractor
    private let ethereumKit: Kit

    private var stateSubject = PublishSubject<State>()

    private(set) var state: State = .connecting {
        didSet {
            stateSubject.onNext(state)
        }
    }

    private var peerMeta: WCPeerMeta?

    init(interactor: WalletConnectInteractor, ethereumKit: Kit) {
        self.interactor = interactor
        self.ethereumKit = ethereumKit

        interactor.connect()
    }

}

extension WalletConnectInitialConnectService {

    var stateObservable: Observable<State> {
        stateSubject.asObservable()
    }

    func approveSession() {
        guard let peerMeta = peerMeta else {
            return
        }

        interactor.approveSession(address: ethereumKit.address.eip55, chainId: 1) // todo: get chainId from EthereumKit
        state = .approved(peerMeta: peerMeta)
    }

    func rejectSession() {
        interactor.rejectSession()
        state = .rejected
    }

}

extension WalletConnectInitialConnectService: IWalletConnectInteractorDelegate {

    func didConnect() {
    }

    func didRequestSession(peerMeta: WCPeerMeta) {
        self.peerMeta = peerMeta
        state = .waitingForApproveSession(peerMeta: peerMeta)
    }

}

extension WalletConnectInitialConnectService {

    enum State {
        case connecting
        case waitingForApproveSession(peerMeta: WCPeerMeta)
        case approved(peerMeta: WCPeerMeta)
        case rejected
    }

}

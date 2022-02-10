import RxSwift
import RxRelay
import WalletConnect
import WalletConnectUtils

class WalletConnectV2XMainService {
    private let disposeBag = DisposeBag()

    private let service: WalletConnectV2Service
    private let pingService: WalletConnectV2PingService
    private let manager: WalletConnectManager
    private let evmChainParser: WalletConnectEvmChainParser

    private var proposal: Session.Proposal?
    private var session: Session?
    private var kitWrappers = [Int: EvmKitWrapper]()

    private var stateRelay = PublishRelay<WalletConnectXMainModule.State>()
    private var connectionStateRelay = PublishRelay<WalletConnectXMainModule.ConnectionState>()
    private var requestRelay = PublishRelay<Request>()
    private var errorRelay = PublishRelay<Error>()

    private(set) var state: WalletConnectXMainModule.State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(session: Session? = nil, uri: String? = nil, service: WalletConnectV2Service, pingService: WalletConnectV2PingService, manager: WalletConnectManager, evmChainParser: WalletConnectEvmChainParser) {
        self.session = session
        self.service = service
        self.pingService = pingService
        self.manager = manager
        self.evmChainParser = evmChainParser

        subscribe(disposeBag, service.receiveProposalObservable) { [weak self] in self?.didReceive(proposal: $0) }
        subscribe(disposeBag, service.receiveSessionObservable) { [weak self] in self?.didReceive(session: $0) }
        subscribe(disposeBag, service.deleteSessionObservable) { [weak self] in self?.didDelete(topic: $0, reason: $1) }

        if let session = session {
            state = .ready
            pingService.ping(topic: session.topic)
        }
    }

    private func didReceive(proposal: Session.Proposal) {
        self.proposal = proposal

        pingService.receiveResponse()
        state = .waitingForApproveSession
    }

    private func didReceive(session: Session) {
        self.session = session

        pingService.receiveResponse()
        state = .ready
    }

    private func didDelete(topic: String, reason: Reason) {
        guard let currentTopic = session?.topic, currentTopic == topic else {
            return
        }

        pingService.disconnect()
        state = .killed
    }

}

extension WalletConnectV2XMainService: IWalletConnectXMainService {

    var appMetaItem: WalletConnectXMainModule.AppMetaItem? {
        if let session = session {
            return WalletConnectXMainModule.AppMetaItem(
                    name: session.peer.name ?? "",
                    url: session.peer.url ?? "",
                    description: session.peer.description ?? "",
                    icons: session.peer.icons ?? []
            )
        }
        if let proposal = proposal {
            return WalletConnectXMainModule.AppMetaItem(
                    name: proposal.proposer.name ?? "",
                    url: proposal.proposer.description ?? "",
                    description: proposal.proposer.url ?? "",
                    icons: proposal.proposer.icons ?? []
            )
        }

        return nil
    }

    var hint: String? {
        "Test v2 support"
    }

    var stateObservable: Observable<WalletConnectXMainModule.State> {
        stateRelay.asObservable()
    }

    var connectionState: WalletConnectXMainModule.ConnectionState {
        pingService.state
    }

    var connectionStateObservable: Observable<WalletConnectXMainModule.ConnectionState> {
        pingService.stateObservable
    }

    var errorObservable: Observable<Error> {
        errorRelay.asObservable()
    }

    func reconnect() {
        guard let session = session else {
            return
        }

        pingService.ping(topic: session.topic)
    }

    func approveSession() {
        guard let proposal = proposal else {
            return
        }

        guard let account = manager.activeAccount else {
            state = .invalid(error: WalletConnectXMainModule.SessionError.noSuitableAccount)
            return
        }

        let chainIds = proposal.permissions.blockchains.compactMap { evmChainParser.chainId(blockchain: $0) }

        let wrappers = chainIds.reduce(into: [Int: EvmKitWrapper]()) {
            $0[$1] = manager.evmKitWrapper(chainId: $1, account: account)
        }

        guard !wrappers.isEmpty else {
            state = .invalid(error: WalletConnectXMainModule.SessionError.unsupportedChainId)
            return
        }

        kitWrappers = wrappers

        let accounts: [String] = chainIds.compactMap { chainId in
            guard let wrapper = wrappers[chainId] else {
                return nil
            }

            return "eip155:\(chainId):\(wrapper.evmKit.address.eip55)"
        }

        service.approve(proposal: proposal, accounts: Set(accounts))
    }

    func rejectSession() {
        if let proposal = proposal {
            service.reject(proposal: proposal)
            pingService.disconnect()
            state = .killed
        }
    }

    func killSession() {
        guard let session = session else {
            return
        }

        service.disconnect(topic: session.topic, reason: Reason(code: 1, message: "Session Killed by User"))
        pingService.disconnect()
        state = .killed
    }

}

extension WalletConnectV2XMainService {

    struct SessionData {
        let proposal: Session.Proposal
        let appMeta: WalletConnectXMainModule.AppMetaItem
    }

}
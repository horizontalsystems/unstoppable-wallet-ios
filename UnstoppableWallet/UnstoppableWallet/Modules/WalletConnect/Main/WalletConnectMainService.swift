import EvmKit
import HsToolKit
import RxRelay
import RxSwift
import WalletConnectSign
import WalletConnectUtils

class WalletConnectMainService {
    private let disposeBag = DisposeBag()

    private let service: WalletConnectService
    private let manager: WalletConnectManager
    private let reachabilityManager: IReachabilityManager
    private let accountManager: AccountManager
    private let proposalHandler: IProposalHandler
    private let proposalValidator: ProposalValidator

    private var proposal: WalletConnectSign.Session.Proposal?
    private(set) var session: WalletConnectSign.Session? {
        didSet {
            sessionUpdatedRelay.accept(session)
        }
    }

    private let connectionStateRelay = PublishRelay<WalletConnectMainModule.ConnectionState>()
    private let requestRelay = PublishRelay<WalletConnectSign.Request>()
    private let errorRelay = PublishRelay<Error>()
    private let sessionUpdatedRelay = PublishRelay<WalletConnectSign.Session?>()

    private let allowedBlockchainsRelay = PublishRelay<[WalletConnectMainModule.BlockchainItem]>()

    private var blockchains = WalletConnectMainModule.BlockchainSet.empty
    private var methods = Set<String>()
    private var events = Set<String>()

    private let stateRelay = PublishRelay<WalletConnectMainModule.State>()
    private(set) var state: WalletConnectMainModule.State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(session: WalletConnectSign.Session? = nil, proposal: WalletConnectSign.Session.Proposal? = nil, service: WalletConnectService, manager: WalletConnectManager, reachabilityManager: IReachabilityManager, accountManager: AccountManager, proposalHandler: IProposalHandler, proposalValidator: ProposalValidator) {
        self.session = session
        self.proposal = proposal
        self.service = service
        self.manager = manager
        self.reachabilityManager = reachabilityManager
        self.accountManager = accountManager
        self.proposalHandler = proposalHandler
        self.proposalValidator = proposalValidator

        subscribe(disposeBag, service.receiveProposalObservable) { [weak self] in
            self?.proposal = $0
            self?.sync(proposal: $0)
        }
        subscribe(disposeBag, service.receiveSessionObservable) { [weak self] in
            self?.session = $0
            self?.didReceive(session: $0)
        }
        subscribe(disposeBag, service.deleteSessionObservable) { [weak self] in
            self?.didDelete(topic: $0, reason: $1)
        }
        subscribe(disposeBag, service.socketConnectionStatusObservable) { [weak self] in
            self?.connectionStateRelay.accept($0)
        }
        connectionStateRelay.accept(service.socketConnectionStatus == .connected ? .connected : .disconnected)

        if let session {
            didReceive(session: session)
        }

        if let proposal {
            sync(proposal: proposal)
        }
    }

    private func sync(proposal: WalletConnectSign.Session.Proposal) {
        do {
            let blockchains = proposalHandler.handle(provider: proposal)
            try proposalValidator.validate(namespaces: proposal.requiredNamespaces, set: blockchains)

            self.blockchains = blockchains
            allowedBlockchainsRelay.accept(allowedBlockchains)

            guard !blockchains.items.isEmpty else {
                state = .invalid(error: WalletConnectMainModule.SessionError.noAnySupportedChainId)
                return
            }

            state = .waitingForApproveSession
        } catch {
            state = .invalid(error: error)
            return
        }
    }

    private func didReceive(session: WalletConnectSign.Session) {
        do {
            let blockchains = proposalHandler.handle(provider: session)
            try proposalValidator.validate(namespaces: session.proposalNamespaces, set: blockchains)

            self.blockchains = blockchains
            allowedBlockchainsRelay.accept(allowedBlockchains)

            state = .ready
        } catch {
            state = .invalid(error: WalletConnectMainModule.SessionError.noAnySupportedChainId)
            return
        }
    }

    private func didDelete(topic: String, reason _: WalletConnectSign.Reason) {
        guard let currentTopic = session?.topic, currentTopic == topic else {
            return
        }

        state = .killed(reason: .killSession) // TODO: ???
    }
}

extension WalletConnectMainService {
    var activeAccountName: String? {
        accountManager.activeAccount?.name
    }

    var appMetaItem: WalletConnectMainModule.AppMetaItem? {
        if let session {
            return WalletConnectMainModule.AppMetaItem(
                name: session.peer.name,
                url: session.peer.url,
                description: session.peer.description,
                icons: session.peer.icons
            )
        }
        if let proposal {
            return WalletConnectMainModule.AppMetaItem(
                name: proposal.proposer.name,
                url: proposal.proposer.url,
                description: proposal.proposer.description,
                icons: proposal.proposer.icons
            )
        }

        return nil
    }

    var allowedBlockchains: [WalletConnectMainModule.BlockchainItem] {
        blockchains.items.sorted { blockchain, blockchain2 in
            blockchain.chainId < blockchain2.chainId
        }
    }

    var hint: String? {
        switch connectionState {
        case .disconnected:
            if state == .waitingForApproveSession || state == .ready {
                return "wallet_connect.no_connection".localized
            }
        case .connecting: return nil
        case .connected: ()
        }

        switch state {
        case let .invalid(error):
            return error.smartDescription
        case .waitingForApproveSession:
            return "wallet_connect.connect_description".localized
        default:
            return nil
        }
    }

    var stateObservable: Observable<WalletConnectMainModule.State> {
        stateRelay.asObservable()
    }

    var sessionUpdatedObservable: Observable<WalletConnectSign.Session?> {
        sessionUpdatedRelay.asObservable()
    }

    var connectionState: WalletConnectMainModule.ConnectionState {
        service.socketConnectionStatus
    }

    var connectionStateObservable: Observable<WalletConnectMainModule.ConnectionState> {
        connectionStateRelay.asObservable()
    }

    var proposalTimeOutAttentionObservable: Observable<Void> {
        Observable.empty()
    }

    var errorObservable: Observable<Error> {
        errorRelay.asObservable()
    }

    var allowedBlockchainsObservable: Observable<[WalletConnectMainModule.BlockchainItem]> {
        allowedBlockchainsRelay.asObservable()
    }

    func reconnect() {
        guard session != nil else {
            return
        }

        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }
    }

    func approveSession() {
        guard let proposal else {
            return
        }

        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

        guard manager.activeAccount != nil else {
            state = .invalid(error: WalletConnectMainModule.SessionError.noSuitableAccount)
            return
        }

        // TODO: check
        let accounts: [WalletConnectUtils.Account] = blockchains.items.compactMap { item in
            Blockchain(
                namespace: item.namespace,
                reference: item.chainId.description
            )
            .flatMap { chain in
                WalletConnectUtils.Account(
                    blockchain: chain,
                    address: item.address
                )
            }
        }

        Task { [weak self, service, blockchains] in
            do {
                try await service.approve(proposal: proposal, accounts: Set(accounts), methods: blockchains.methods, events: blockchains.events)
            } catch {
                self?.errorRelay.accept(error)
            }
        }
    }

    func rejectSession() {
        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

        if let proposal {
            Task { [weak self, service] in
                defer {
                    self?.state = .killed(reason: .rejectProposal)
                }
                do {
                    try await service.reject(proposal: proposal)
                } catch {
                    self?.errorRelay.accept(error)
                }
            }
        }
    }

    func killSession() {
        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

        guard let session else {
            return
        }

        service.disconnect(topic: session.topic, reason: RejectionReason(code: 1, message: "Session Killed by User"))
        state = .killed(reason: .killSession) // TODO: ???
    }
}

extension WalletConnectMainService {
    struct RejectionReason: Reason {
        let code: Int
        let message: String
    }

    struct SessionData {
        let proposal: WalletConnectSign.Session.Proposal
        let appMeta: WalletConnectMainModule.AppMetaItem
    }
}

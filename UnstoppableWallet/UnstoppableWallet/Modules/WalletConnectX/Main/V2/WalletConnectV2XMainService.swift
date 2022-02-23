import RxSwift
import RxRelay
import WalletConnect
import WalletConnectUtils
import HsToolKit
import EthereumKit

class WalletConnectV2XMainService {
    private let disposeBag = DisposeBag()

    private let service: WalletConnectV2Service
    private let pingService: WalletConnectV2PingService
    private let manager: WalletConnectManager
    private let reachabilityManager: IReachabilityManager
    private let accountManager: IAccountManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmChainParser: WalletConnectEvmChainParser

    private var proposal: Session.Proposal?
    private var session: Session?
    private var kitWrappers = [Int: EvmKitWrapper]()

    private let connectionStateRelay = PublishRelay<WalletConnectXMainModule.ConnectionState>()
    private let requestRelay = PublishRelay<Request>()
    private let errorRelay = PublishRelay<Error>()

    private let allowedBlockchainsRelay = PublishRelay<[Int: WalletConnectXMainModule.Blockchain]>()
    private(set) var allowedBlockchains = [Int: WalletConnectXMainModule.Blockchain]() {
        didSet {
            allowedBlockchainsRelay.accept(allowedBlockchains)
        }
    }

    private let stateRelay = PublishRelay<WalletConnectXMainModule.State>()
    private(set) var state: WalletConnectXMainModule.State = .idle {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(session: Session? = nil, uri: String? = nil, service: WalletConnectV2Service, pingService: WalletConnectV2PingService, manager: WalletConnectManager, reachabilityManager: IReachabilityManager, accountManager: IAccountManager, evmBlockchainManager: EvmBlockchainManager, evmChainParser: WalletConnectEvmChainParser) {
        self.session = session
        self.service = service
        self.pingService = pingService
        self.manager = manager
        self.reachabilityManager = reachabilityManager
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager
        self.evmChainParser = evmChainParser

        subscribe(disposeBag, service.receiveProposalObservable) { [weak self] in
            self?.didReceive(proposal: $0)
        }
        subscribe(disposeBag, service.receiveSessionObservable) { [weak self] in
            self?.didReceive(session: $0)
        }
        subscribe(disposeBag, service.deleteSessionObservable) { [weak self] in
            self?.didDelete(topic: $0, reason: $1)
        }
        subscribe(disposeBag, pingService.stateObservable) { [weak self] in
            self?.connectionStateRelay.accept($0)
        }
        subscribe(disposeBag, reachabilityManager.reachabilityObservable) { [weak self] reachable in
            if reachable {
                if let topic = self?.session?.topic {
                    self?.pingService.ping(topic: topic)
                }
            } else {
                if self?.session != nil {
                    self?.pingService.disconnect()
                }
            }
        }

        if let session = session {
            state = .ready
            allowedBlockchains = initialBlockchains

            pingService.ping(topic: session.topic)
        }
    }

    private func didReceive(proposal: Session.Proposal) {
        self.proposal = proposal
        allowedBlockchains = initialBlockchains

        guard !initialBlockchains.isEmpty else {
            state = .invalid(error: WalletConnectXMainModule.SessionError.unsupportedChainId)
            return
        }

        state = .waitingForApproveSession
        pingService.receiveResponse()
    }

    private func didReceive(session: Session) {
        self.session = session
        allowedBlockchains = initialBlockchains

        state = .ready
        pingService.receiveResponse()
    }

    private func didDelete(topic: String, reason: Reason) {
        guard let currentTopic = session?.topic, currentTopic == topic else {
            return
        }

        pingService.disconnect()
        state = .killed
    }

    private var initialBlockchains: [Int: WalletConnectXMainModule.Blockchain] {
        guard let seed = accountManager.activeAccount?.type.mnemonicSeed else {
            return [:]
        }
        if let session = session {
            let sessionAccountData = session.accounts.compactMap {
                evmChainParser.parse(string: $0)
            }

            var blockchains = [Int: WalletConnectXMainModule.Blockchain]()
            sessionAccountData.forEach { account in
                let blockchain = account.address.map {
                    WalletConnectXMainModule.Blockchain(address: $0, selected: true)
                }
                blockchains[account.chainId] = blockchain
            }
            return blockchains
        }
        if let proposal = proposal {
            // get chainIds
            let proposalAccountData = proposal.permissions.blockchains.compactMap {
                evmChainParser.parse(string: $0)
            }
            let allowedChains = proposalAccountData.compactMap {
                evmBlockchainManager.chain(chainId: $0.chainId)
            }
            // get addresses
            var blockchains = [Int: WalletConnectXMainModule.Blockchain]()
            allowedChains.forEach { chain in
                guard let address = try? Signer.address(seed: seed, chain: chain) else {
                    return
                }
                blockchains[chain.id] = WalletConnectXMainModule.Blockchain(address: address.eip55, selected: true)
            }
            return blockchains
        }

        return [:]
    }

}

extension WalletConnectV2XMainService: IWalletConnectXMainService {

    var activeAccountName: String? {
        accountManager.activeAccount?.name
    }

    var appMetaItem: WalletConnectXMainModule.AppMetaItem? {
        if let session = session {
            return WalletConnectXMainModule.AppMetaItem(
                    editable: false,
                    name: session.peer.name ?? "",
                    url: session.peer.url ?? "",
                    description: session.peer.description ?? "",
                    icons: session.peer.icons ?? []
            )
        }
        if let proposal = proposal {
            return WalletConnectXMainModule.AppMetaItem(
                    editable: true,
                    name: proposal.proposer.name ?? "",
                    url: proposal.proposer.url ?? "",
                    description: proposal.proposer.description ?? "",
                    icons: proposal.proposer.icons ?? []
            )
        }

        return nil
    }

    var hint: String? {
        switch connectionState {
        case .disconnected:
            if state == .waitingForApproveSession || state == .ready {
                return "wallet_connect.no_connection"
            }
        case .connecting: return nil
        case .connected: ()
        }

        switch state {
        case .invalid(let error):
            return error.smartDescription
        case .waitingForApproveSession:
            return "wallet_connect.connect_description"
        default:
            return nil
        }
    }

    var stateObservable: Observable<WalletConnectXMainModule.State> {
        stateRelay.asObservable()
    }

    var connectionState: WalletConnectXMainModule.ConnectionState {
        pingService.state
    }

    var connectionStateObservable: Observable<WalletConnectXMainModule.ConnectionState> {
        connectionStateRelay.asObservable()
    }

    var errorObservable: Observable<Error> {
        errorRelay.asObservable()
    }

    var allowedBlockchainsObservable: Observable<[Int: WalletConnectXMainModule.Blockchain]> {
        allowedBlockchainsRelay.asObservable()
    }

    func toggle(chainId: Int) {
        guard let blockchain = allowedBlockchains[chainId],
           blockchain.selected,
           allowedBlockchains.filter({ key, value in value.selected }).count > 1 else {
            return
        }
        allowedBlockchains[chainId] = WalletConnectXMainModule.Blockchain(address: blockchain.address, selected: !blockchain.selected)
    }

    func reconnect() {
        guard let session = session else {
            return
        }

        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

        pingService.ping(topic: session.topic)
    }

    func approveSession() {
        guard let proposal = proposal else {
            return
        }

        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

        guard let account = manager.activeAccount else {
            state = .invalid(error: WalletConnectXMainModule.SessionError.noSuitableAccount)
            return
        }

        kitWrappers = [:]
        var accounts = [String]()
        allowedBlockchains.forEach { chainId, blockchain in
            guard blockchain.selected, let wrapper = manager.evmKitWrapper(chainId: chainId, account: account) else {
                return
            }
            kitWrappers[chainId] = wrapper

            accounts.append("eip155:\(chainId):\(blockchain.address)")
        }

        guard !kitWrappers.isEmpty else {
            state = .invalid(error: WalletConnectXMainModule.SessionError.unsupportedChainId)
            return
        }

        service.approve(proposal: proposal, accounts: Set(accounts))
    }

    func rejectSession() {
        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

        if let proposal = proposal {
            service.reject(proposal: proposal)
            pingService.disconnect()
            state = .killed
        }
    }

    func killSession() {
        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }

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

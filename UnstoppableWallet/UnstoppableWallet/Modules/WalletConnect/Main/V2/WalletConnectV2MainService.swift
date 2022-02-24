import RxSwift
import RxRelay
import WalletConnect
import WalletConnectUtils
import HsToolKit
import EthereumKit

class WalletConnectV2MainService {
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

    private let connectionStateRelay = PublishRelay<WalletConnectMainModule.ConnectionState>()
    private let requestRelay = PublishRelay<Request>()
    private let errorRelay = PublishRelay<Error>()

    private let allowedBlockchainsRelay = PublishRelay<[WalletConnectMainModule.Blockchain]>()
    private var blockchains = Set<WalletConnectMainModule.Blockchain>()

    private let stateRelay = PublishRelay<WalletConnectMainModule.State>()
    private(set) var state: WalletConnectMainModule.State = .idle {
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
            blockchains = initialBlockchains
            allowedBlockchainsRelay.accept(allowedBlockchains)

            pingService.ping(topic: session.topic)
        }
    }

    private func didReceive(proposal: Session.Proposal) {
        self.proposal = proposal
        blockchains = initialBlockchains
        allowedBlockchainsRelay.accept(allowedBlockchains)

        guard !initialBlockchains.isEmpty else {
            state = .invalid(error: WalletConnectMainModule.SessionError.unsupportedChainId)
            return
        }

        state = .waitingForApproveSession
        pingService.receiveResponse()
    }

    private func didReceive(session: Session) {
        self.session = session
        blockchains = initialBlockchains
        allowedBlockchainsRelay.accept(allowedBlockchains)

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

    private var initialBlockchains: Set<WalletConnectMainModule.Blockchain> {
        guard let seed = accountManager.activeAccount?.type.mnemonicSeed else {
            return Set()
        }

        if let session = session {
            let sessionAccountData = session.accounts.compactMap {
                evmChainParser.parse(string: $0)
            }

            var blockchains = Set<WalletConnectMainModule.Blockchain>()
            sessionAccountData.forEach { account in
                guard let evmBlockchain = evmBlockchainManager.blockchain(chainId: account.chainId),
                      let address = account.address else {
                    return
                }

                blockchains.insert(WalletConnectMainModule.Blockchain(chainId: account.chainId, evmBlockchain: evmBlockchain, address: address, selected: true))
            }
            return blockchains
        }

        if let proposal = proposal {
            // get chainIds
            let chainIds = proposal.permissions.blockchains.compactMap {
                evmChainParser.parse(string: $0)?.chainId
            }

            // get addresses
            var blockchains = Set<WalletConnectMainModule.Blockchain>()
            chainIds.forEach { chainId in
                guard let evmBlockchain = evmBlockchainManager.blockchain(chainId: chainId),
                      let chain = evmBlockchainManager.chain(chainId: chainId),
                      let address = try? Signer.address(seed: seed, chain: chain) else {
                    return
                }

                blockchains.insert(WalletConnectMainModule.Blockchain(chainId: chainId, evmBlockchain: evmBlockchain, address: address.eip55, selected: true))
            }
            return blockchains
        }

        return Set()
    }

}

extension WalletConnectV2MainService: IWalletConnectMainService {

    var activeAccountName: String? {
        accountManager.activeAccount?.name
    }

    var appMetaItem: WalletConnectMainModule.AppMetaItem? {
        if let session = session {
            return WalletConnectMainModule.AppMetaItem(
                    editable: false,
                    name: session.peer.name ?? "",
                    url: session.peer.url ?? "",
                    description: session.peer.description ?? "",
                    icons: session.peer.icons ?? []
            )
        }
        if let proposal = proposal {
            return WalletConnectMainModule.AppMetaItem(
                    editable: true,
                    name: proposal.proposer.name ?? "",
                    url: proposal.proposer.url ?? "",
                    description: proposal.proposer.description ?? "",
                    icons: proposal.proposer.icons ?? []
            )
        }

        return nil
    }

    var allowedBlockchains: [WalletConnectMainModule.Blockchain] {
        blockchains.sorted { blockchain, blockchain2 in
            blockchain.chainId < blockchain2.chainId
        }
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

    var stateObservable: Observable<WalletConnectMainModule.State> {
        stateRelay.asObservable()
    }

    var connectionState: WalletConnectMainModule.ConnectionState {
        pingService.state
    }

    var connectionStateObservable: Observable<WalletConnectMainModule.ConnectionState> {
        connectionStateRelay.asObservable()
    }

    var errorObservable: Observable<Error> {
        errorRelay.asObservable()
    }

    var allowedBlockchainsObservable: Observable<[WalletConnectMainModule.Blockchain]> {
        allowedBlockchainsRelay.asObservable()
    }

    func toggle(chainId: Int) {
        guard let blockchain = blockchains.first(where: { $0.chainId == chainId }) else {
            return
        }
        if blockchain.selected, blockchains.filter({ $0.selected }).count < 2 {
            return
        }

        let toggledBlockchain = WalletConnectMainModule.Blockchain(chainId: chainId, evmBlockchain: blockchain.evmBlockchain, address: blockchain.address, selected: !blockchain.selected)
        blockchains.update(with: toggledBlockchain)
        allowedBlockchainsRelay.accept(allowedBlockchains)
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

        guard manager.activeAccount != nil else {
            state = .invalid(error: WalletConnectMainModule.SessionError.noSuitableAccount)
            return
        }

        var accounts = [String]()
        blockchains.forEach { blockchain in
            guard blockchain.selected,
                  evmBlockchainManager.blockchain(chainId: blockchain.chainId) != nil else {
                return
            }

            accounts.append("eip155:\(blockchain.chainId):\(blockchain.address)")
        }

        guard !accounts.isEmpty else {
            state = .invalid(error: WalletConnectMainModule.SessionError.unsupportedChainId)
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

extension WalletConnectV2MainService {

    struct SessionData {
        let proposal: Session.Proposal
        let appMeta: WalletConnectMainModule.AppMetaItem
    }

}

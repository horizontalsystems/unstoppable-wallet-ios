import RxSwift
import RxRelay
import WalletConnectUtils
import WalletConnectSign
import HsToolKit
import EthereumKit

class WalletConnectV2MainService {
    private let disposeBag = DisposeBag()

    private let service: WalletConnectV2Service
    private let pingService: WalletConnectV2PingService
    private let manager: WalletConnectManager
    private let reachabilityManager: IReachabilityManager
    private let accountManager: AccountManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let evmChainParser: WalletConnectEvmChainParser

    private var proposal: WalletConnectSign.Session.Proposal?
    private var session: WalletConnectSign.Session?

    private let connectionStateRelay = PublishRelay<WalletConnectMainModule.ConnectionState>()
    private let requestRelay = PublishRelay<WalletConnectSign.Request>()
    private let errorRelay = PublishRelay<Error>()

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

    init(session: WalletConnectSign.Session? = nil, uri: String? = nil, service: WalletConnectV2Service, pingService: WalletConnectV2PingService, manager: WalletConnectManager, reachabilityManager: IReachabilityManager, accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager, evmChainParser: WalletConnectEvmChainParser) {
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
                self?.pingService.ping()
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

            self.pingService.topic = session.topic
            pingService.ping()
        }
    }

    private func didReceive(proposal: WalletConnectSign.Session.Proposal) {
        self.proposal = proposal
        blockchains = initialBlockchains
        allowedBlockchainsRelay.accept(allowedBlockchains)

        guard !initialBlockchains.items.isEmpty else {
            state = .invalid(error: WalletConnectMainModule.SessionError.unsupportedChainId)
            return
        }

        state = .waitingForApproveSession
        pingService.receiveResponse()
    }

    private func didReceive(session: WalletConnectSign.Session) {
        self.session = session
        blockchains = initialBlockchains
        allowedBlockchainsRelay.accept(allowedBlockchains)

        state = .ready
        pingService.topic = session.topic
        pingService.receiveResponse()
    }

    private func didDelete(topic: String, reason: WalletConnectSign.Reason) {
        guard let currentTopic = session?.topic, currentTopic == topic else {
            return
        }

        pingService.topic = nil
        pingService.disconnect()
        state = .killed
    }

    private var initialBlockchains: WalletConnectMainModule.BlockchainSet {
        guard let seed = accountManager.activeAccount?.type.mnemonicSeed else {
            return .empty
        }

//        if let session = session {
//            let sessionAccountData = session.accounts.compactMap {
//                evmChainParser.parse(string: $0)
//            }
//
//            var blockchains = Set<WalletConnectMainModule.BlockchainItem>()
//            sessionAccountData.forEach { account in
//                guard let blockchain = evmBlockchainManager.blockchain(chainId: account.chainId),
//                      let address = account.address else {
//                    return
//                }
//
//                blockchains.insert(WalletConnectMainModule.BlockchainItem(chainId: account.chainId, blockchain: blockchain, address: address, selected: true))
//            }
//            return blockchains
//        }
//
        let supportedNamespace = "eip155" // Support only EVM blockchains yet
        if let proposal = proposal,
           let eip155 = proposal.requiredNamespaces[supportedNamespace] {
            // get chainIds
            let chainIds = eip155.chains.compactMap { Int($0.reference) }

            // get addresses
            var blockchainItems = Set<WalletConnectMainModule.BlockchainItem>()
            chainIds.forEach { chainId in
                guard let blockchain = evmBlockchainManager.blockchain(chainId: chainId),
                      let chain = evmBlockchainManager.chain(chainId: chainId),
                      let address = try? Signer.address(seed: seed, chain: chain) else {
                    return
                }

                blockchainItems.insert(WalletConnectMainModule.BlockchainItem(
                        namespace: supportedNamespace,
                        chainId: chainId,
                        blockchain: blockchain,
                        address: address.eip55,
                        selected: true
                ))
            }

            return WalletConnectMainModule.BlockchainSet(items: blockchainItems, methods: eip155.methods, events: eip155.events)
        }

        return .empty
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
                    name: session.peer.name,
                    url: session.peer.url,
                    description: session.peer.description,
                    icons: session.peer.icons
            )
        }
        if let proposal = proposal {
            return WalletConnectMainModule.AppMetaItem(
                    editable: true,
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

    var allowedBlockchainsObservable: Observable<[WalletConnectMainModule.BlockchainItem]> {
        allowedBlockchainsRelay.asObservable()
    }

    func toggle(chainId: Int) {
        guard let blockchain = blockchains.items.first(where: { $0.chainId == chainId }) else {
            return
        }
        if blockchain.selected, blockchains.items.filter({ $0.selected }).count < 2 {
            return
        }

        let toggledBlockchain = WalletConnectMainModule.BlockchainItem(
                namespace: "eip155",
                chainId: chainId,
                blockchain: blockchain.blockchain,
                address: blockchain.address,
                selected: !blockchain.selected
        )
        blockchains.items.update(with: toggledBlockchain)
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

        pingService.topic = session.topic
        pingService.ping()
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

        var accounts = [WalletConnectUtils.Account]()
        blockchains.items.forEach { blockchain in
            guard blockchain.selected,
                  evmBlockchainManager.blockchain(chainId: blockchain.chainId) != nil else {
                return
            }


            if let wcBlockchain = WalletConnectUtils.Blockchain(namespace: blockchain.namespace, reference: blockchain.chainId.description),
               let account = WalletConnectUtils.Account(blockchain: wcBlockchain, address: blockchain.address) {
                accounts.append(account)
            }
        }

        guard !accounts.isEmpty else {
            state = .invalid(error: WalletConnectMainModule.SessionError.unsupportedChainId)
            return
        }

        service.approve(proposal: proposal, accounts: Set(accounts), methods: blockchains.methods, events: blockchains.events)
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
        let proposal: WalletConnectSign.Session.Proposal
        let appMeta: WalletConnectMainModule.AppMetaItem
    }

}

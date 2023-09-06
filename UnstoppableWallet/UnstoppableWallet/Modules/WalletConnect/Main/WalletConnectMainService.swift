import RxSwift
import RxRelay
import WalletConnectUtils
import WalletConnectSign
import HsToolKit
import EvmKit

class WalletConnectMainService {
    private let disposeBag = DisposeBag()

    private let service: WalletConnectService
    private let manager: WalletConnectManager
    private let reachabilityManager: IReachabilityManager
    private let accountManager: AccountManager
    private let evmBlockchainManager: EvmBlockchainManager

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

    init(session: WalletConnectSign.Session? = nil, proposal: WalletConnectSign.Session.Proposal? = nil, service: WalletConnectService, manager: WalletConnectManager, reachabilityManager: IReachabilityManager, accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager) {
        self.session = session
        self.proposal = proposal
        self.service = service
        self.manager = manager
        self.reachabilityManager = reachabilityManager
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager

        subscribe(disposeBag, service.receiveProposalObservable) { [weak self] in
            self?.proposal = $0
            self?.sync(proposal: $0)
        }
        subscribe(disposeBag, service.receiveSessionObservable) { [weak self] in
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
            state = .ready
            do {
                blockchains = try blockchains(by: session)
                allowedBlockchainsRelay.accept(allowedBlockchains)
            } catch {
                state = .invalid(error: WalletConnectMainModule.SessionError.noAnySupportedChainId)
                return
            }
        }

        if let proposal {
            sync(proposal: proposal)
        }
    }

    private func sync(proposal: WalletConnectSign.Session.Proposal) {
        do {
            blockchains = try blockchains(by: proposal)
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
        self.session = session
        do {
            blockchains = try blockchains(by: session)
            allowedBlockchainsRelay.accept(allowedBlockchains)

            state = .ready
        } catch {
            state = .invalid(error: WalletConnectMainModule.SessionError.noAnySupportedChainId)
            return
        }
    }

    private func didDelete(topic: String, reason: WalletConnectSign.Reason) {
        guard let currentTopic = session?.topic, currentTopic == topic else {
            return
        }

        state = .killed(reason: .killSession) // todo: ???
    }

    private func blockchains(by session: WalletConnectSign.Session) throws ->  WalletConnectMainModule.BlockchainSet {
        guard let account = accountManager.activeAccount,
              let eip155 = session.namespaces["eip155"] else {
            throw WalletConnectMainModule.SessionError.unsupportedChainId
        }

        let wcBlockchains = eip155.accounts.map { $0.blockchain }
        let items = blockchainItems(blockchains: wcBlockchains, account: account, selected: true)
        return .init(items: Set(items), methods: eip155.methods, events: eip155.events)
    }

    private func blockchains(by proposal: WalletConnectSign.Session.Proposal) throws ->  WalletConnectMainModule.BlockchainSet {
        guard let account = accountManager.activeAccount else {
            return .empty
        }
        // check that we have only eip155 namespace for working

        var items = [WalletConnectMainModule.BlockchainItem]()
        if proposal.requiredNamespaces.count == 0 {
            // do nothing
        } else if proposal.requiredNamespaces.count == 1, let requiredEip155 = proposal.requiredNamespaces["eip155"] {
            // no any chains to sign
            guard let wcRequiredChains = requiredEip155.chains?.compactMap({ $0 }) else {
                return .empty
            }

            items = blockchainItems(blockchains: wcRequiredChains, account: account, selected: true)
            // We must sign all required chains
            guard items.count == wcRequiredChains.count else {
                throw WalletConnectMainModule.SessionError.unsupportedChainId
            }
        } else {
            throw WalletConnectMainModule.SessionError.unsupportedChainId
        }
        // Add all optionals chains from proposal

        guard let eip155 = proposal.requiredNamespaces["eip155"] ?? proposal.optionalNamespaces?["eip155"] else {
            throw WalletConnectMainModule.SessionError.unsupportedChainId
        }

        if let optionalEip155 = proposal.optionalNamespaces?["eip155"],
           let optionalChains = optionalEip155.chains?.compactMap({ $0 }) {

            items.append(contentsOf: blockchainItems(blockchains: optionalChains, account: account, selected: false))
        }


        return .init(items: Set(items), methods: eip155.methods, events: eip155.events)
    }

    private func blockchainItems(blockchains: [WalletConnectUtils.Blockchain], account: Account, selected: Bool) -> [WalletConnectMainModule.BlockchainItem] {
        blockchains.compactMap { wcBlockchain in
            guard let chainId = Int(wcBlockchain.reference),
                  let blockchain = evmBlockchainManager.blockchain(chainId: chainId) else {
                // not valid chainId for eip155 or not supported blockchain
                return nil
            }
            let chain = evmBlockchainManager.chain(blockchainType: blockchain.type)

            guard let address = try? WalletConnectManager.evmAddress(account: account, chain: chain) else {
                // can't get address for chain
                return nil
            }
            return WalletConnectMainModule.BlockchainItem(
                    namespace: wcBlockchain.namespace,
                    chainId: chainId,
                    blockchain: blockchain,
                    address: address.eip55,
                    selected: selected)
        }
    }

}

extension WalletConnectMainService {

    var activeAccountName: String? {
        accountManager.activeAccount?.name
    }

    var appMetaItem: WalletConnectMainModule.AppMetaItem? {
        if let session = session {
            return WalletConnectMainModule.AppMetaItem(
                    name: session.peer.name,
                    url: session.peer.url,
                    description: session.peer.description,
                    icons: session.peer.icons
            )
        }
        if let proposal = proposal {
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
        case .invalid(let error):
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

    var proposalTimeOutAttentionObservable: Observable<()> {
        Observable.empty()
    }

    var errorObservable: Observable<Error> {
        errorRelay.asObservable()
    }

    var allowedBlockchainsObservable: Observable<[WalletConnectMainModule.BlockchainItem]> {
        allowedBlockchainsRelay.asObservable()
    }

    func select(chainId: Int) {
        // not required for V2 // todo: Refactor and remove
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
        guard session != nil else {
            return
        }

        guard reachabilityManager.isReachable else {
            errorRelay.accept(AppError.noConnection)
            return
        }
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

        let chains = evmBlockchainManager.allBlockchains.compactMap { blockchain in
            evmBlockchainManager.chain(blockchainType: blockchain.type)
        }

        let accounts = chains.compactMap { chain in
            if let firstBlockchainItem = blockchains.items.first(where: { item in item.chainId == chain.id }),
                    let wcBlockchain = WalletConnectUtils.Blockchain(namespace: firstBlockchainItem.namespace, reference: chain.id.description),
                    let wcAccount = WalletConnectUtils.Account(blockchain: wcBlockchain, address: firstBlockchainItem.address) {
                        return wcAccount
            }
            return nil
        }

        guard !accounts.isEmpty else {
            state = .invalid(error: WalletConnectMainModule.SessionError.noAnySupportedChainId)
            return
        }

        let set = Set(accounts)
        Task { [weak self, service, blockchains] in
            do {
                try await service.approve(proposal: proposal, accounts: set, methods: blockchains.methods, events: blockchains.events)
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

        if let proposal = proposal {
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

        guard let session = session else {
            return
        }

        service.disconnect(topic: session.topic, reason: RejectionReason(code: 1, message: "Session Killed by User"))
        state = .killed(reason: .killSession) //todo: ???
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

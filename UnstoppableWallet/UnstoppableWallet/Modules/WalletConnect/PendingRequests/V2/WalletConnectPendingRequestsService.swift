import RxSwift
import RxRelay

class WalletConnectPendingRequestsService {
    private let disposeBag = DisposeBag()

    private let sessionManager: WalletConnectSessionManager
    private let accountManager: AccountManager
    private let evmBlockchainManager: EvmBlockchainManager
    private let signService: IWalletConnectSignService

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private var accounts = [Account]()

    private let showPendingRequestRelay = PublishRelay<WalletConnectRequest>()

    init(sessionManager: WalletConnectSessionManager, accountManager: AccountManager, evmBlockchainManager: EvmBlockchainManager, signService: IWalletConnectSignService) {
        self.sessionManager = sessionManager
        self.accountManager = accountManager
        self.evmBlockchainManager = evmBlockchainManager
        self.signService = signService

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] in self?.sync(accounts: $0) }
        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.syncPendingRequests() }
        subscribe(disposeBag, sessionManager.activePendingRequestsObservable) { [weak self] _ in self?.syncPendingRequests() }

        sync(accounts: accountManager.accounts)
        syncPendingRequests()
    }

    private func sync(accounts: [Account]) {
        guard let activeAccountId = accountManager.activeAccount?.id else {
            return
        }

        if self.accounts.isEmpty {
            self.accounts = accounts.sorted { account, _ in account.id == activeAccountId }
        } else {
            self.accounts = accounts
        }

        syncPendingRequests()
    }

    private func syncPendingRequests() {
        guard let activeAccountId = accountManager.activeAccount?.id else {
            return
        }
        var items = [Item]()
        let allSessions = sessionManager.allSessions

        accounts.forEach { account in
            let pendingRequests = sessionManager.pendingRequests(accountId: account.id)
            guard !pendingRequests.isEmpty else {
                return
            }
            items.append(Item(
                    accountId: account.id,
                    accountName: account.name,
                    active: account.id == activeAccountId,
                    requests: pendingRequests.compactMap { request in
                        let session = allSessions.first(where: { $0.topic == request.topic })
                        return RequestItem(
                                id: request.id.intValue,
                                sessionName: session?.peer.name ?? "N/A",
                                sessionImageUrl: session?.peer.icons.first,
                                method: RequestMethod(request.method),
                                chainId: request.chainId.reference
                        )
                    }.sorted { $0.id > $1.id }
            ))
        }

        self.items = items
    }

}

extension WalletConnectPendingRequestsService {

    func blockchain(chainId: String?) -> String? {
        guard let chainId = chainId,
              let id = Int(chainId),
              let blockchain = evmBlockchainManager.blockchain(chainId: id) else {
            return nil
        }

        return blockchain.name
    }

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var showPendingRequestObservable: Observable<WalletConnectRequest> {
        showPendingRequestRelay.asObservable()
    }

    func select(requestId: Int) {
        guard let request = sessionManager.pendingRequests().first(where: { $0.id.intValue == requestId }) else {
            return
        }
        let session = sessionManager.sessions.first { $0.topic == request.topic }

        guard let chainId = Int(request.chainId.reference),
              let blockchain = evmBlockchainManager.blockchain(chainId: chainId),
              let account = accountManager.activeAccount,
              let address = try? WalletConnectManager.evmAddress(
                      account: account,
                      chain: evmBlockchainManager.chain(blockchainType: blockchain.type)
              ) else {
            return
        }

        let chain = WalletConnectRequest.Chain(id: chainId, chainName: blockchain.name, address: address.eip55)

        guard let wcRequest = try? WalletConnectRequestMapper.map(dAppName: session?.peer.name, chain: chain, request: request) else {
            return
        }

        showPendingRequestRelay.accept(wcRequest)
    }

    func select(accountId: String) {
        accountManager.set(activeAccountId: accountId)
    }

    func onReject(id: Int) {
        signService.rejectRequest(id: id)
    }

}

extension WalletConnectPendingRequestsService {

    struct RequestItem {
        let id: Int
        let sessionName: String
        let sessionImageUrl: String?
        let method: RequestMethod
        let chainId: String?
    }

    struct Item {
        let accountId: String
        let accountName: String
        let active: Bool
        let requests: [RequestItem]
    }

    enum RequestMethod {
        case ethSign
        case personalSign
        case ethSignTypedData
        case ethSendTransaction
        case unsupported

        init(_ string: String) {
            switch string {
            case "eth_sign": self = .ethSign
            case "personal_sign": self = .personalSign
            case "eth_signTypedData": self = .ethSignTypedData
            case "eth_sendTransaction": self = .ethSendTransaction
            default: self = .unsupported
            }
        }
    }
    
}

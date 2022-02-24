import RxSwift
import RxRelay
import WalletConnect

class WalletConnectV2PendingRequestsService {
    private let disposeBag = DisposeBag()

    private let sessionManager: WalletConnectV2SessionManager
    private let accountManager: IAccountManager

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private var accounts = [Account]()

    private let showPendingRequestRelay = PublishRelay<WalletConnectRequest>()

    init(sessionManager: WalletConnectV2SessionManager, accountManager: IAccountManager) {
        self.sessionManager = sessionManager
        self.accountManager = accountManager

        subscribe(disposeBag, accountManager.accountsObservable) { [weak self] in self?.sync(accounts: $0) }
        subscribe(disposeBag, accountManager.activeAccountObservable) { [weak self] _ in self?.syncPendingRequests() }
        subscribe(disposeBag, sessionManager.pendingRequestsObservable) { [weak self] _ in self?.syncPendingRequests() }

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
                        RequestItem(
                                id: request.id,
                                sessionName: allSessions.first(where: { $0.topic == request.topic })?.peer.name ?? "",
                                method: request.method,
                                chainId: request.chainId
                        )
                    }
            ))
        }

        self.items = items
    }

}

extension WalletConnectV2PendingRequestsService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var showPendingRequestObservable: Observable<WalletConnectRequest> {
        showPendingRequestRelay.asObservable()
    }

    func select(requestId: Int64) {
        guard let request = sessionManager.pendingRequests().first(where: { $0.id == requestId }) else {
            return
        }
        let session = sessionManager.sessions.first { $0.topic == request.topic }
        guard let wcRequest = try? WalletConnectV2RequestMapper.map(dAppName: session?.peer.name, request: request) else {
            return
        }

        showPendingRequestRelay.accept(wcRequest)
    }

    func select(accountId: String) {
        accountManager.set(activeAccountId: accountId)
    }

}

extension WalletConnectV2PendingRequestsService {

    struct RequestItem {
        let id: Int64
        let sessionName: String
        let method: String
        let chainId: String?
    }

    struct Item {
        let accountId: String
        let accountName: String
        let active: Bool
        let requests: [RequestItem]
    }

}

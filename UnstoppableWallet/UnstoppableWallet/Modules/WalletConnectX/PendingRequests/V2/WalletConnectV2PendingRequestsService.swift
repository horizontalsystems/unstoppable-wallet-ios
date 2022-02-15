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

    init(sessionManager: WalletConnectV2SessionManager, accountManager: IAccountManager) {
        self.sessionManager = sessionManager
        self.accountManager = accountManager

        subscribe(disposeBag, sessionManager.pendingRequestsObservable) { [weak self] _ in self?.syncPendingRequests() }

        syncPendingRequests()
    }

    private func syncPendingRequests() {
        guard let activeAccountId = accountManager.activeAccount?.id else {
            return
        }
        var items = [Item]()
        let allSessions = sessionManager.allSessions

        accountManager.accounts.forEach { account in
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

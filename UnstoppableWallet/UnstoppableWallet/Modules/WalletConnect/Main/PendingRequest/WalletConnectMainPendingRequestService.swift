import Foundation
import RxRelay
import RxSwift
import WalletConnectSign

class WalletConnectMainPendingRequestService {
    private let disposeBag = DisposeBag()

    private let accountManager: AccountManager
    private let sessionManager: WalletConnectSessionManager
    private let requestHandler: IWalletConnectRequestHandler

    private let evmBlockchainManager: EvmBlockchainManager
    private let signService: IWalletConnectSignService
    private var session: WalletConnectSign.Session?

    private let itemsRelay = PublishRelay<[Item]>()
    private(set) var items = [Item]() {
        didSet {
            itemsRelay.accept(items)
        }
    }

    private let showPendingRequestRelay = PublishRelay<WalletConnectRequest>()

    init(service: WalletConnectMainService, accountManager: AccountManager, sessionManager: WalletConnectSessionManager, requestHandler: IWalletConnectRequestHandler, evmBlockchainManager: EvmBlockchainManager, signService: IWalletConnectSignService) {
        self.accountManager = accountManager
        self.sessionManager = sessionManager
        self.requestHandler = requestHandler
        self.evmBlockchainManager = evmBlockchainManager
        self.signService = signService
        session = service.session

        subscribe(disposeBag, service.sessionUpdatedObservable) { [weak self] in self?.update(session: $0) }
        subscribe(disposeBag, sessionManager.activePendingRequestsObservable) { [weak self] _ in self?.syncPendingRequests() }

        syncPendingRequests()
    }

    private func update(session: WalletConnectSign.Session?) {
        self.session = session
        syncPendingRequests()
    }

    private func syncPendingRequests() {
        guard let session else {
            items = []
            return
        }

        items = sessionManager.pendingRequests()
            .filter { $0.topic == session.topic }
            .map { request in
                Item(
                    id: request.id.intValue,
                    sessionName: session.peer.name,
                    sessionImageUrl: session.peer.icons.first,
                    methodName: requestHandler.name(by: request.method),
                    chainId: request.chainId.reference
                )
            }
            .sorted { $0.id > $1.id }
    }
}

extension WalletConnectMainPendingRequestService {
    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var showPendingRequestObservable: Observable<WalletConnectRequest> {
        showPendingRequestRelay.asObservable()
    }

    func blockchain(chainId: String?) -> String? {
        guard let chainId,
              let id = Int(chainId),
              let blockchain = evmBlockchainManager.blockchain(chainId: id)
        else {
            return nil
        }

        return blockchain.name
    }

    func select(requestId: Int) {
        guard let request = sessionManager.pendingRequests().first(where: { $0.id.intValue == requestId }) else {
            return
        }
        guard let session = sessionManager.sessions.first(where: { $0.topic == request.topic }) else {
            return
        }

        let result = requestHandler.handle(session: session, request: request)
        switch result {
        case let .unsuccessful(error):
            print("Cant select request because: \(error?.localizedDescription ?? "nil")")
        case .handled: ()
        case let .request(request):
            showPendingRequestRelay.accept(request)
        }
    }

    func onReject(id: Int) {
        signService.rejectRequest(id: id)
    }
}

extension WalletConnectMainPendingRequestService {
    struct Item {
        let id: Int
        let sessionName: String
        let sessionImageUrl: String?
        let methodName: String?
        let chainId: String?
    }
}

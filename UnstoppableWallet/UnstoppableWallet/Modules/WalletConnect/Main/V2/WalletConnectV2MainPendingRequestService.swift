import Foundation
import RxSwift
import RxRelay
import WalletConnectSign

class WalletConnectV2MainPendingRequestService {
    private let disposeBag = DisposeBag()

    private let sessionManager: WalletConnectV2SessionManager
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

    init(service: WalletConnectV2MainService, sessionManager: WalletConnectV2SessionManager, evmBlockchainManager: EvmBlockchainManager, signService: IWalletConnectSignService) {
        self.sessionManager = sessionManager
        self.evmBlockchainManager = evmBlockchainManager
        self.signService = signService
        self.session = service.session

        subscribe(disposeBag, service.sessionUpdatedObservable) { [weak self] in self?.update(session: $0) }
        subscribe(disposeBag, sessionManager.pendingRequestsObservable) { [weak self] _ in self?.syncPendingRequests() }

        syncPendingRequests()
    }

    private func update(session: WalletConnectSign.Session?) {
        self.session = session
        syncPendingRequests()
    }

    private func syncPendingRequests() {
        guard let session = session else {
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
                            method: RequestMethod(request.method),
                            chainId: request.chainId.reference
                    )
                }
                .sorted { $0.id > $1.id }
    }

}

extension WalletConnectV2MainPendingRequestService {

    var itemsObservable: Observable<[Item]> {
        itemsRelay.asObservable()
    }

    var showPendingRequestObservable: Observable<WalletConnectRequest> {
        showPendingRequestRelay.asObservable()
    }

    func blockchain(chainId: String?) -> String? {
        guard let chainId = chainId,
              let id = Int(chainId),
              let blockchain = evmBlockchainManager.blockchain(chainId: id) else {
            return nil
        }

        return blockchain.name
    }

    func select(requestId: Int) {
        guard let request = sessionManager.pendingRequests().first(where: { $0.id.intValue == requestId }) else {
            return
        }
        let session = sessionManager.sessions.first { $0.topic == request.topic }
        guard let wcRequest = try? WalletConnectV2RequestMapper.map(dAppName: session?.peer.name, request: request) else {
            return
        }

        showPendingRequestRelay.accept(wcRequest)
    }

    func onReject(id: Int) {
        signService.rejectRequest(id: id)
    }

}

extension WalletConnectV2MainPendingRequestService {

    struct Item {
        let id: Int
        let sessionName: String
        let sessionImageUrl: String?
        let method: RequestMethod
        let chainId: String?
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

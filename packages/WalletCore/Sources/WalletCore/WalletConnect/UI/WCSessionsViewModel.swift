import Combine
import Foundation

class WCSessionsViewModel: ObservableObject {
    struct Item: Identifiable {
        let session: WCSessionItem
        let host: String
        let iconUrl: URL?
        let requests: [RequestItem]
        var id: String { session.topic }
    }

    struct RequestItem: Identifiable {
        let pending: WCPendingRequestItem
        let label: String
        var id: String { pending.id.string }
    }

    private let manager: WCManager?
    private var cancellables = Set<AnyCancellable>()
    private var kitCancellables = Set<AnyCancellable>()

    @Published private(set) var items = [Item]()
    private let invalidUrlSubject = PassthroughSubject<Void, Never>()

    init() {
        manager = Core.shared.walletConnect

        manager?.kitPublisher
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.subscribe(kit: $0) }
            .store(in: &cancellables)
    }

    private func subscribe(kit: WCKit) {
        WCLog.log("sessions vm: subscribed to kit")
        kitCancellables.removeAll()
        kit.sessionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(sessions: $0, kit: kit) }
            .store(in: &kitCancellables)
        kit.pendingRequestsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.sync(sessions: kit.sessions, kit: kit) }
            .store(in: &kitCancellables)
    }

    private func sync(sessions: [WCSessionItem], kit: WCKit) {
        WCLog.log("sessions vm: sync sessions=\(sessions.count)")
        items = sessions.map { session in
            Item(
                session: session,
                host: session.peer.flatMap { URLComponents(string: $0.url)?.host } ?? session.dAppName,
                iconUrl: session.peer?.icons.first.flatMap { URL(string: $0) },
                requests: kit.pendingRequests(topic: session.topic).map { RequestItem(pending: $0, label: Self.label(method: $0.method)) }
            )
        }
    }

    var invalidUrlPublisher: AnyPublisher<Void, Never> { invalidUrlSubject.eraseToAnyPublisher() }

    func refresh() {
        WCLog.log("sessions vm: refresh startedKit=\(manager?.startedKit != nil)")
        guard let kit = manager?.startedKit else { return }
        sync(sessions: kit.sessions, kit: kit)
    }

    func pair(uri: String) {
        WCPresenter.pair(uri: uri)
    }

    func open(request: RequestItem) {
        manager?.startedKit?.open(requestId: request.pending.id)
    }

    func disconnect(item: Item) {
        guard let kit = manager?.startedKit else { return }
        Task {
            try? await kit.disconnect(topic: item.session.topic)
        }
    }

    static func label(method: String) -> String {
        if method.hasPrefix("wallet_") {
            return "wallet_connect.list.request.approve".localized
        }
        if method.contains("sign"), !method.hasSuffix("Transaction"), !method.hasSuffix("Transactions"), !method.hasSuffix("XDR") {
            return "wallet_connect.list.request.sign".localized
        }
        return "wallet_connect.list.request.confirm".localized
    }
}

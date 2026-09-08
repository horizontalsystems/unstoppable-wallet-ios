import Combine
import HsToolKit
import ReownWalletKit

// Owns the {account, topic, approved namespaces} binding; the SDK session list is never authoritative for it
class WCSessionService {
    private let signClient: IWCSignClient
    private let storage: WCSessionStorage
    private let accountProvider: IWCAccountProvider
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    private let sessionsSubject = CurrentValueSubject<[WCSessionItem], Never>([])

    init(signClient: IWCSignClient, storage: WCSessionStorage, accountProvider: IWCAccountProvider, logger: Logger? = nil) {
        self.signClient = signClient
        self.storage = storage
        self.accountProvider = accountProvider
        self.logger = logger

        accountProvider.activeAccountIdPublisher
            .sink { [weak self] _ in self?.sync() }
            .store(in: &cancellables)
        accountProvider.deletedAccountIdPublisher
            .sink { [weak self] in self?.handleDeleted(accountId: $0) }
            .store(in: &cancellables)
        signClient.sessionsPublisher
            .sink { [weak self] in
                WCLog.log("sessions: sdk sessionsPublisher count=\($0.count)")
                self?.sync()
            }
            .store(in: &cancellables)
        signClient.sessionUpdatePublisher
            .sink { [weak self] in self?.handleUpdate(topic: $0.topic, namespaces: $0.namespaces) }
            .store(in: &cancellables)

        sync()
    }

    var sessionsPublisher: AnyPublisher<[WCSessionItem], Never> {
        sessionsSubject.eraseToAnyPublisher()
    }

    var sessions: [WCSessionItem] {
        sessionsSubject.value
    }

    // the only write path for the approved set: an explicit user approve
    func store(session: Session, accountId: String) throws {
        let namespaces = WCSessionNamespaces(sessionNamespaces: session.namespaces)
        try storage.save(session: WCSessionRecord(topic: session.topic, accountId: accountId, dAppName: session.peer.name, namespaces: namespaces))
        WCLog.log("sessions: stored topic=\(session.topic.prefix(8)) account=\(accountId)")
        logger?.info("stored session \(session.topic) for account \(accountId)")
        sync()
    }

    func sessionInfo(topic: String, accountId: String) throws -> WCSessionInfo? {
        guard let record = try storage.session(topic: topic), record.accountId == accountId else {
            return nil
        }
        let peer = signClient.sessions.first { $0.topic == topic }?.peer
        return try WCSessionInfo(topic: topic, accountId: accountId, dAppName: record.dAppName, approvedAccounts: record.sessionNamespaces().accounts, peerUrl: peer?.url, peerIconUrl: peer?.icons.first)
    }

    func disconnect(topic: String) async throws {
        try await signClient.disconnect(topic: topic)
        try storage.delete(topics: [topic])
        sync()
    }

    // legacy sessions from the removed old module have no approval record; disconnect them once at start so
    // they do not linger as live-but-invisible sessions the dApp still considers connected
    func disconnectOrphans() {
        Task { [weak self] in
            guard let self else { return }
            let known = Set((try? storage.sessions().map(\.topic)) ?? [])
            for session in signClient.sessions where !known.contains(session.topic) {
                do {
                    try await signClient.disconnect(topic: session.topic)
                    WCLog.log("sessions: disconnected orphan topic=\(session.topic.prefix(8))")
                } catch {
                    logger?.error("orphan disconnect \(session.topic) failed: \(error)")
                }
            }
        }
    }

    func sync() {
        do {
            let live = Dictionary(uniqueKeysWithValues: signClient.sessions.map { ($0.topic, $0) })
            let records = try storage.sessions()

            let stale = records.map(\.topic).filter { live[$0] == nil }
            if !stale.isEmpty {
                logger?.info("dropping \(stale.count) session records no longer known to the SDK")
                try storage.delete(topics: stale)
            }

            let known = Set(records.map(\.topic))
            for topic in live.keys where !known.contains(topic) {
                logger?.warning("SDK session \(topic) has no approval record, ignoring")
            }

            let activeAccountId = accountProvider.activeAccountId
            WCLog.log("sessions sync: live=\(live.count) records=\(records.count) stale=\(stale.count) active=\(activeAccountId ?? "nil")")
            let items = try records
                .filter { $0.accountId == activeAccountId && live[$0.topic] != nil }
                .map { try WCSessionItem(topic: $0.topic, accountId: $0.accountId, dAppName: $0.dAppName, peer: live[$0.topic]?.peer, namespaces: $0.sessionNamespaces()) }
            WCLog.log("sessions sync: items=\(items.count)")
            sessionsSubject.send(items)
        } catch {
            WCLog.log("sessions sync: failed \(error)")
            logger?.error("session sync failed: \(error)")
        }
    }

    private func handleDeleted(accountId: String) {
        WCLog.log("sessions: account deleted \(accountId)")
        Task { [weak self] in
            await self?.disconnectAll(accountId: accountId)
        }
    }

    private func disconnectAll(accountId: String) async {
        let records = (try? storage.sessions(accountId: accountId)) ?? []
        for record in records {
            do {
                try await signClient.disconnect(topic: record.topic)
            } catch {
                logger?.error("disconnect \(record.topic) failed: \(error)")
            }
        }
        try? storage.delete(accountId: accountId)
        sync()
    }

    // dApp-driven updates never touch the persisted approval; verifiers read the snapshot
    private func handleUpdate(topic: String, namespaces: [String: SessionNamespace]) {
        WCLog.log("sessions: dApp update topic=\(topic.prefix(8)) namespaces=\(Array(namespaces.keys))")
        guard let record = try? storage.session(topic: topic), let persisted = try? record.sessionNamespaces() else {
            return
        }
        let proposed = WCSessionNamespaces(sessionNamespaces: namespaces)
        if !persisted.contains(proposed) {
            logger?.warning("session update for \(topic) extends the approved namespaces, keeping the persisted approval")
        }
    }
}

import Combine
import HsToolKit
import ReownWalletKit

// Owns the {account, topic, approved namespaces} binding; the SDK session list is never authoritative for it
class WCNSessionService {
    private let signClient: IWCNSignClient
    private let storage: WCNSessionStorage
    private let accountProvider: IWCNAccountProvider
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    private let sessionsSubject = CurrentValueSubject<[WCNSessionItem], Never>([])

    init(signClient: IWCNSignClient, storage: WCNSessionStorage, accountProvider: IWCNAccountProvider, logger: Logger? = nil) {
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
                WCNLog.log("sessions: sdk sessionsPublisher count=\($0.count)")
                self?.sync()
            }
            .store(in: &cancellables)
        signClient.sessionUpdatePublisher
            .sink { [weak self] in self?.handleUpdate(topic: $0.topic, namespaces: $0.namespaces) }
            .store(in: &cancellables)

        sync()
    }

    var sessionsPublisher: AnyPublisher<[WCNSessionItem], Never> {
        sessionsSubject.eraseToAnyPublisher()
    }

    var sessions: [WCNSessionItem] {
        sessionsSubject.value
    }

    // the only write path for the approved set: an explicit user approve
    func store(session: Session, accountId: String) throws {
        let namespaces = WCNSessionNamespaces(sessionNamespaces: session.namespaces)
        try storage.save(session: WCNSessionRecord(topic: session.topic, accountId: accountId, dAppName: session.peer.name, namespaces: namespaces))
        WCNLog.log("sessions: stored topic=\(session.topic.prefix(8)) account=\(accountId)")
        logger?.info("stored session \(session.topic) for account \(accountId)")
        sync()
    }

    func sessionInfo(topic: String, accountId: String) throws -> WCNSessionInfo? {
        guard let record = try storage.session(topic: topic), record.accountId == accountId else {
            return nil
        }
        let peer = signClient.sessions.first { $0.topic == topic }?.peer
        return try WCNSessionInfo(topic: topic, accountId: accountId, dAppName: record.dAppName, approvedAccounts: record.sessionNamespaces().accounts, peerUrl: peer?.url, peerIconUrl: peer?.icons.first)
    }

    func disconnect(topic: String) async throws {
        try await signClient.disconnect(topic: topic)
        try storage.delete(topics: [topic])
        sync()
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
            WCNLog.log("sessions sync: live=\(live.count) records=\(records.count) stale=\(stale.count) active=\(activeAccountId ?? "nil")")
            let items = try records
                .filter { $0.accountId == activeAccountId && live[$0.topic] != nil }
                .map { try WCNSessionItem(topic: $0.topic, accountId: $0.accountId, dAppName: $0.dAppName, peer: live[$0.topic]?.peer, namespaces: $0.sessionNamespaces()) }
            WCNLog.log("sessions sync: items=\(items.count)")
            sessionsSubject.send(items)
        } catch {
            WCNLog.log("sessions sync: failed \(error)")
            logger?.error("session sync failed: \(error)")
        }
    }

    private func handleDeleted(accountId: String) {
        WCNLog.log("sessions: account deleted \(accountId)")
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
        WCNLog.log("sessions: dApp update topic=\(topic.prefix(8)) namespaces=\(Array(namespaces.keys))")
        guard let record = try? storage.session(topic: topic), let persisted = try? record.sessionNamespaces() else {
            return
        }
        let proposed = WCNSessionNamespaces(sessionNamespaces: namespaces)
        if !persisted.contains(proposed) {
            logger?.warning("session update for \(topic) extends the approved namespaces, keeping the persisted approval")
        }
    }
}

import Combine
import Foundation
import HsToolKit
import ReownWalletKit

// Thin facade: wires the services together and exposes their publishers; no per-chain or per-method logic lives here
class WCNKit {
    private let signClient: IWCNSignClient
    private let sessionService: WCNSessionService
    private let requestService: WCNRequestService
    private let directHandlers: WCNDirectHandlerRegistry
    private let responder: WCNResponder
    private let pairingService: WCNPairingService
    private let verifyService: WCNVerifyService
    private let namespaceBuilder: WCNNamespaceBuilder
    private let accountProvider: IWCNAccountProvider
    private let lockProvider: IWCNLockProvider
    private let foregroundProvider: IWCNForegroundProvider
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    private let requestSubject = PassthroughSubject<WCNRequestItem, Never>()
    private let proposalSubject = PassthroughSubject<WCNProposalItem, Never>()
    private let expiredRequestSubject = PassthroughSubject<RPCID, Never>()
    private let pendingChangedSubject = PassthroughSubject<Void, Never>()

    private let stateLock = NSLock()
    // requests already surfaced this session or already pending at start: counted in the list, never auto-shown again
    private var seen = Set<RPCID>()
    // the latest request waiting for a foreground+unlocked moment; a newer one overwrites it (last wins)
    private var activeRequest: WCNRequestItem?
    // arrival order, so the last request to arrive wins even if an earlier one finishes parsing later
    private var arrivalCounter: UInt64 = 0
    private var activeSeq: UInt64 = 0
    private var isForeground = false
    // one request sheet at a time: a new request waits until the current one is dismissed
    private var isPresenting = false

    init(signClient: IWCNSignClient, sessionService: WCNSessionService, requestService: WCNRequestService, directHandlers: WCNDirectHandlerRegistry, responder: WCNResponder, pairingService: WCNPairingService, verifyService: WCNVerifyService, namespaceBuilder: WCNNamespaceBuilder, accountProvider: IWCNAccountProvider, lockProvider: IWCNLockProvider, foregroundProvider: IWCNForegroundProvider, logger: Logger? = nil) {
        self.signClient = signClient
        self.sessionService = sessionService
        self.requestService = requestService
        self.directHandlers = directHandlers
        self.responder = responder
        self.pairingService = pairingService
        self.verifyService = verifyService
        self.namespaceBuilder = namespaceBuilder
        self.accountProvider = accountProvider
        self.lockProvider = lockProvider
        self.foregroundProvider = foregroundProvider
        self.logger = logger
    }

    // pending requests present at start are only counted; the active-request pointer surfaces one on the next foreground+unlocked moment
    func start() {
        WCNLog.log("kit start: subscribing, pending=\(signClient.pendingRequests.count) sessions=\(signClient.sessions.count)")
        isForeground = foregroundProvider.isActive
        signClient.sessionRequestPublisher
            .sink { [weak self] in self?.handle(request: $0.request, context: $0.context) }
            .store(in: &cancellables)
        signClient.requestExpirationPublisher
            .sink { [weak self] in self?.expire(requestId: $0) }
            .store(in: &cancellables)
        signClient.sessionProposalPublisher
            .sink { [weak self] in self?.handle(proposal: $0.proposal, context: $0.context) }
            .store(in: &cancellables)
        lockProvider.isLockedPublisher
            .sink { [weak self] locked in
                if !locked { self?.presentActiveIfPossible() }
            }
            .store(in: &cancellables)
        foregroundProvider.isActivePublisher
            .sink { [weak self] active in
                guard let self else { return }
                stateLock.lock()
                isForeground = active
                stateLock.unlock()
                if active { presentActiveIfPossible() }
            }
            .store(in: &cancellables)
        responder.answeredPublisher
            .sink { [weak self] in
                self?.forget(requestId: $0)
                self?.pendingChangedSubject.send()
            }
            .store(in: &cancellables)

        // seed the seen set so requests that were already pending are shown only in the list, never popped up
        stateLock.lock()
        seen = Set(signClient.pendingRequests.map(\.request.id))
        stateLock.unlock()
        WCNLog.log("kit start: done, seeded=\(signClient.pendingRequests.count)")
    }

    var requestPublisher: AnyPublisher<WCNRequestItem, Never> { requestSubject.eraseToAnyPublisher() }
    var proposalPublisher: AnyPublisher<WCNProposalItem, Never> { proposalSubject.eraseToAnyPublisher() }
    var expiredRequestPublisher: AnyPublisher<RPCID, Never> { expiredRequestSubject.eraseToAnyPublisher() }
    // received, answered or expired: the SDK pending list changed
    var pendingRequestsPublisher: AnyPublisher<Void, Never> { pendingChangedSubject.eraseToAnyPublisher() }
    var sessionsPublisher: AnyPublisher<[WCNSessionItem], Never> { sessionService.sessionsPublisher }
    var sessions: [WCNSessionItem] { sessionService.sessions }

    func pair(uri: String) async throws {
        WCNLog.log("kit pair: start")
        do {
            try await pairingService.pair(uri: uri)
            WCNLog.log("kit pair: done")
        } catch {
            WCNLog.log("kit pair: failed \(error)")
            throw error
        }
    }

    func disconnect(topic: String) async throws {
        WCNLog.log("kit disconnect: topic=\(topic.prefix(8))")
        try await sessionService.disconnect(topic: topic)
    }

    func verifyState(context: VerifyContext?) -> WCNVerifyState {
        verifyService.state(context: context)
    }

    func defenseState(context: VerifyContext?) -> WCNDefenseState {
        verifyService.defenseState(context: context)
    }

    func defenseState(peerUrl: String) -> WCNDefenseState {
        verifyService.defenseState(peerUrl: peerUrl)
    }

    func pendingRequests(topic: String) -> [WCNPendingRequestItem] {
        signClient.pendingRequests
            .filter { $0.request.topic == topic }
            .map { WCNPendingRequestItem(id: $0.request.id, method: $0.request.method) }
    }

    // pending requests bound to the active account: the badge count for parked (unanswered) requests
    var pendingRequestCount: Int {
        guard let accountId = accountProvider.activeAccountId else { return 0 }
        return signClient.pendingRequests.filter { (try? sessionService.sessionInfo(topic: $0.request.topic, accountId: accountId)) != nil }.count
    }

    // re-runs a pending request through the service so the user can open it from the sessions list
    func open(requestId: RPCID) {
        guard let pending = signClient.pendingRequests.first(where: { $0.request.id == requestId }) else {
            WCNLog.log("kit open: pending id=\(requestId.string) not found")
            return
        }
        WCNLog.log("kit open: id=\(requestId.string) method=\(pending.request.method)")
        handle(request: pending.request, context: pending.context, forced: true)
    }

    func reject(item: WCNRequestItem) async throws {
        guard let request = item.request else { return }
        WCNLog.log("kit reject request: id=\(request.payload.id.string)")
        try await responder.reject(request: request.payload, reason: .userRejected)
    }

    func blockchainProposals(for proposal: Session.Proposal) -> [WCNBlockchainProposal] {
        guard let account = accountProvider.activeAccount else {
            return []
        }
        return namespaceBuilder.proposals(required: proposal.requiredNamespaces, optional: proposal.optionalNamespaces, account: account)
    }

    func validationError(for proposal: Session.Proposal) -> Error? {
        do {
            try namespaceBuilder.validate(required: proposal.requiredNamespaces, selected: blockchainProposals(for: proposal))
            return nil
        } catch {
            return error
        }
    }

    // the only path that writes the approved set: an explicit user approve
    func approve(proposal: Session.Proposal, selected: [WCNBlockchainProposal]) async throws {
        guard let accountId = accountProvider.activeAccountId else {
            WCNLog.log("kit approve: no active account")
            throw KitError.noActiveAccount
        }
        WCNLog.log("kit approve: proposal=\(proposal.id) selected=\(selected.map(\.chain.absoluteString))")
        try namespaceBuilder.validate(required: proposal.requiredNamespaces, selected: selected)
        let session = try await signClient.approve(proposalId: proposal.id, namespaces: namespaceBuilder.sessionNamespaces(selected: selected))
        WCNLog.log("kit approve: sdk session topic=\(session.topic.prefix(8)) peer=\(session.peer.name)")
        try sessionService.store(session: session, accountId: accountId)
        WCNLog.log("kit approve: stored")
    }

    func reject(proposal: Session.Proposal) async throws {
        WCNLog.log("kit reject proposal: \(proposal.id)")
        try await signClient.rejectSession(proposalId: proposal.id)
    }

    private func handle(proposal: Session.Proposal, context: VerifyContext?) {
        WCNLog.log("kit proposal: id=\(proposal.id) name=\(proposal.proposer.name) url=\(proposal.proposer.url) verify=\(String(describing: context?.validation)) origin=\(context?.origin ?? "-") required=\(Array(proposal.requiredNamespaces.keys)) optional=\(Array((proposal.optionalNamespaces ?? [:]).keys))")
        proposalSubject.send(WCNProposalItem(proposal: proposal, context: context, verifyState: verifyService.state(context: context), blockchainProposals: blockchainProposals(for: proposal)))
    }

    // reown hands the publisher the head of the pending queue, not necessarily the request that just arrived
    // (while an earlier request is unanswered it keeps replaying the old one), so an explicit open aside, treat
    // every signal as "pending changed" and reconcile against the full pending list to find the new requests
    private func handle(request: Request, context: VerifyContext?, forced: Bool = false) {
        WCNLog.log("kit request: id=\(request.id.string) method=\(request.method) topic=\(request.topic.prefix(8)) chain=\(request.chainId.absoluteString) forced=\(forced)")
        if forced {
            stateLock.lock()
            // keep it in the seen set: an explicit open shows it once, the reconcile scan must not re-present it
            seen.insert(request.id)
            arrivalCounter += 1
            let seq = arrivalCounter
            stateLock.unlock()
            gateAndProcess(request: request, context: context, seq: seq)
            return
        }

        pendingChangedSubject.send()

        var candidates = signClient.pendingRequests
        if !candidates.contains(where: { $0.request.id == request.id }) {
            candidates.append((request: request, context: context))
        }

        stateLock.lock()
        let fresh = candidates.filter { seen.insert($0.request.id).inserted }
        stateLock.unlock()

        guard !fresh.isEmpty else {
            WCNLog.log("kit request: nothing new among \(candidates.count) pending")
            return
        }

        for pending in fresh {
            stateLock.lock()
            arrivalCounter += 1
            let seq = arrivalCounter
            stateLock.unlock()
            gateAndProcess(request: pending.request, context: pending.context, seq: seq)
        }
    }

    // visibility gate: only requests of a session bound to the active account reach the service
    private func gateAndProcess(request: Request, context: VerifyContext?, seq: UInt64) {
        // requests of another account stay in the seen set on purpose: switching to that account must not pop them up
        guard let accountId = accountProvider.activeAccountId,
              let session = try? sessionService.sessionInfo(topic: request.topic, accountId: accountId)
        else {
            WCNLog.log("kit request: id=\(request.id.string) ignored, topic not bound to active account \(accountProvider.activeAccountId ?? "nil")")
            logger?.warning("request \(request.method) for topic \(request.topic) does not belong to the active account, ignoring")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let result = await requestService.process(request: request, context: context, session: session)
            WCNLog.log("kit request: id=\(request.id.string) result=\(result)")
            emit(WCNRequestItem(requestId: request.id, result: result, session: session), seq: seq)
        }
    }

    private func emit(_ incoming: WCNRequestItem, seq: UInt64 = 0) {
        switch incoming.result {
        case .rejected:
            return
        case let .direct(request):
            respondDirect(request: request, session: incoming.session)
            return
        case .transaction, .signMessage:
            break
        }
        stateLock.lock()
        // keep the last request to have arrived, regardless of which finished parsing first
        if seq >= activeSeq {
            activeRequest = incoming
            activeSeq = seq
        }
        stateLock.unlock()
        WCNLog.log("kit emit: id=\(incoming.requestId.string) queued as active seq=\(seq)")
        presentActiveIfPossible()
    }

    // shows the pending active request when foreground, unlocked and no request sheet is already up
    private func presentActiveIfPossible() {
        stateLock.lock()
        guard isForeground, !lockProvider.isLocked, !isPresenting, let item = activeRequest else {
            stateLock.unlock()
            return
        }
        activeRequest = nil
        isPresenting = true
        stateLock.unlock()
        WCNLog.log("kit present: id=\(item.requestId.string)")
        requestSubject.send(item)
    }

    // the request sheet was dismissed (answered, rejected or swiped): release the slot and show the next, if any
    func notifyRequestDismissed() {
        stateLock.lock()
        isPresenting = false
        stateLock.unlock()
        WCNLog.log("kit dismissed: presenting slot released")
        // let the dismissal animation finish before presenting the next queued request, or SwiftUI drops it
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.presentActiveIfPossible()
        }
    }

    // answered without a screen; an unregistered direct method is refused as unsupported
    private func respondDirect(request: WCNRequest, session: WCNSessionInfo) {
        Task { [weak self] in
            guard let self else { return }
            do {
                WCNLog.log("kit direct: id=\(request.payload.id.string) method=\(request.payload.method) handler=\(directHandlers.handler(for: request.payload) != nil)")
                if let handler = directHandlers.handler(for: request.payload) {
                    try await handler.respond(request: request, session: session)
                } else {
                    try await responder.reject(request: request.payload, reason: .unsupportedMethod)
                }
            } catch {
                logger?.error("direct response failed for id=\(request.payload.id.string): \(error)")
            }
        }
    }

    private func forget(requestId: RPCID) {
        stateLock.lock()
        seen.remove(requestId)
        if activeRequest?.requestId == requestId { activeRequest = nil }
        stateLock.unlock()
    }

    private func expire(requestId: RPCID) {
        WCNLog.log("kit expire: id=\(requestId.string)")
        stateLock.lock()
        if activeRequest?.requestId == requestId { activeRequest = nil }
        seen.remove(requestId)
        stateLock.unlock()
        expiredRequestSubject.send(requestId)
        pendingChangedSubject.send()
    }
}

extension WCNKit {
    enum KitError: Error {
        case noActiveAccount
    }
}

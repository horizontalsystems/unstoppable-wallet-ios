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
    private let logger: Logger?
    private var cancellables = Set<AnyCancellable>()

    private let requestSubject = PassthroughSubject<WCNRequestItem, Never>()
    private let proposalSubject = PassthroughSubject<WCNProposalItem, Never>()
    private let expiredRequestSubject = PassthroughSubject<RPCID, Never>()
    private let pendingChangedSubject = PassthroughSubject<Void, Never>()

    // requests that arrived while the app was locked; released on unlock, dropped on expiration
    private let queueLock = NSLock()
    private var queued = [WCNRequestItem]()

    init(signClient: IWCNSignClient, sessionService: WCNSessionService, requestService: WCNRequestService, directHandlers: WCNDirectHandlerRegistry, responder: WCNResponder, pairingService: WCNPairingService, verifyService: WCNVerifyService, namespaceBuilder: WCNNamespaceBuilder, accountProvider: IWCNAccountProvider, lockProvider: IWCNLockProvider, logger: Logger? = nil) {
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
        self.logger = logger
    }

    // subscriptions are attached before pending requests are replayed, so a request arriving mid-start is not lost
    func start() {
        WCNLog.log("kit start: subscribing, pending=\(signClient.pendingRequests.count) sessions=\(signClient.sessions.count)")
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
                if !locked { self?.flushQueue() }
            }
            .store(in: &cancellables)
        responder.answeredPublisher
            .sink { [weak self] _ in self?.pendingChangedSubject.send() }
            .store(in: &cancellables)

        for pending in signClient.pendingRequests {
            WCNLog.log("kit start: replaying pending id=\(pending.request.id.string) method=\(pending.request.method)")
            handle(request: pending.request, context: pending.context)
        }
        WCNLog.log("kit start: done")
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

    // re-runs a pending request through the service so the user can open it from the sessions list
    func open(requestId: RPCID) {
        guard let pending = signClient.pendingRequests.first(where: { $0.request.id == requestId }) else {
            WCNLog.log("kit open: pending id=\(requestId.string) not found")
            return
        }
        WCNLog.log("kit open: id=\(requestId.string) method=\(pending.request.method)")
        handle(request: pending.request, context: pending.context)
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

    // visibility gate: only requests of a session bound to the active account reach the service
    private func handle(request: Request, context: VerifyContext?) {
        WCNLog.log("kit request: id=\(request.id.string) method=\(request.method) topic=\(request.topic.prefix(8)) chain=\(request.chainId.absoluteString)")
        pendingChangedSubject.send()
        guard let accountId = accountProvider.activeAccountId,
              let session = try? sessionService.sessionInfo(topic: request.topic, accountId: accountId)
        else {
            WCNLog.log("kit request: ignored, topic not bound to active account \(accountProvider.activeAccountId ?? "nil")")
            logger?.warning("request \(request.method) for topic \(request.topic) does not belong to the active account, ignoring")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let result = await requestService.process(request: request, context: context, session: session)
            WCNLog.log("kit request: id=\(request.id.string) result=\(result)")
            emit(WCNRequestItem(requestId: request.id, result: result, session: session))
        }
    }

    private func emit(_ incoming: WCNRequestItem) {
        switch incoming.result {
        case .rejected:
            return
        case let .direct(request):
            respondDirect(request: request, session: incoming.session)
            return
        case .transaction, .signMessage:
            break
        }
        if lockProvider.isLocked {
            queueLock.lock()
            queued.append(incoming)
            queueLock.unlock()
            WCNLog.log("kit emit: locked, queued id=\(incoming.requestId.string)")
            logger?.info("app is locked, queued request id=\(incoming.requestId.string)")
        } else {
            WCNLog.log("kit emit: id=\(incoming.requestId.string)")
            requestSubject.send(incoming)
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

    private func flushQueue() {
        queueLock.lock()
        let pending = queued
        queued.removeAll()
        queueLock.unlock()
        WCNLog.log("kit unlock: flushing \(pending.count) queued")
        pending.forEach { requestSubject.send($0) }
    }

    private func expire(requestId: RPCID) {
        WCNLog.log("kit expire: id=\(requestId.string)")
        queueLock.lock()
        queued.removeAll { $0.requestId == requestId }
        queueLock.unlock()
        expiredRequestSubject.send(requestId)
        pendingChangedSubject.send()
    }
}

extension WCNKit {
    enum KitError: Error {
        case noActiveAccount
    }
}

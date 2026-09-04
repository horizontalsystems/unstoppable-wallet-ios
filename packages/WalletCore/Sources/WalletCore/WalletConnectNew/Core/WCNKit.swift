import Combine
import Foundation
import HsToolKit
import ReownWalletKit

// Thin facade: wires the services together and exposes their publishers; no per-chain or per-method logic lives here
class WCNKit {
    private let signClient: IWCNSignClient
    private let sessionService: WCNSessionService
    private let requestService: WCNRequestService
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

    // requests that arrived while the app was locked; released on unlock, dropped on expiration
    private let queueLock = NSLock()
    private var queued = [WCNRequestItem]()

    init(signClient: IWCNSignClient, sessionService: WCNSessionService, requestService: WCNRequestService, pairingService: WCNPairingService, verifyService: WCNVerifyService, namespaceBuilder: WCNNamespaceBuilder, accountProvider: IWCNAccountProvider, lockProvider: IWCNLockProvider, logger: Logger? = nil) {
        self.signClient = signClient
        self.sessionService = sessionService
        self.requestService = requestService
        self.pairingService = pairingService
        self.verifyService = verifyService
        self.namespaceBuilder = namespaceBuilder
        self.accountProvider = accountProvider
        self.lockProvider = lockProvider
        self.logger = logger
    }

    // subscriptions are attached before pending requests are replayed, so a request arriving mid-start is not lost
    func start() {
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

        for pending in signClient.pendingRequests {
            handle(request: pending.request, context: pending.context)
        }
    }

    var requestPublisher: AnyPublisher<WCNRequestItem, Never> { requestSubject.eraseToAnyPublisher() }
    var proposalPublisher: AnyPublisher<WCNProposalItem, Never> { proposalSubject.eraseToAnyPublisher() }
    var expiredRequestPublisher: AnyPublisher<RPCID, Never> { expiredRequestSubject.eraseToAnyPublisher() }
    var pairingWaitingPublisher: AnyPublisher<Bool, Never> { pairingService.isWaitingPublisher }
    var sessionsPublisher: AnyPublisher<[WCNSessionItem], Never> { sessionService.sessionsPublisher }
    var sessions: [WCNSessionItem] { sessionService.sessions }

    func pair(uri: String) async throws {
        try await pairingService.pair(uri: uri)
    }

    func disconnect(topic: String) async throws {
        try await sessionService.disconnect(topic: topic)
    }

    func verifyState(context: VerifyContext?) -> WCNVerifyState {
        verifyService.state(context: context)
    }

    func blockchainProposals(for proposal: Session.Proposal) -> [WCNBlockchainProposal] {
        guard let account = accountProvider.activeAccount else {
            return []
        }
        return namespaceBuilder.proposals(required: proposal.requiredNamespaces, optional: proposal.optionalNamespaces, account: account)
    }

    // the only path that writes the approved set: an explicit user approve
    func approve(proposal: Session.Proposal, selected: [WCNBlockchainProposal]) async throws {
        guard let accountId = accountProvider.activeAccountId else {
            throw KitError.noActiveAccount
        }
        try namespaceBuilder.validate(required: proposal.requiredNamespaces, selected: selected)
        let session = try await signClient.approve(proposalId: proposal.id, namespaces: namespaceBuilder.sessionNamespaces(selected: selected))
        try sessionService.store(session: session, accountId: accountId)
    }

    func reject(proposal: Session.Proposal) async throws {
        try await signClient.rejectSession(proposalId: proposal.id)
    }

    private func handle(proposal: Session.Proposal, context: VerifyContext?) {
        proposalSubject.send(WCNProposalItem(proposal: proposal, verifyState: verifyService.state(context: context), blockchainProposals: blockchainProposals(for: proposal)))
    }

    // visibility gate: only requests of a session bound to the active account reach the service
    private func handle(request: Request, context: VerifyContext?) {
        guard let accountId = accountProvider.activeAccountId,
              let session = try? sessionService.sessionInfo(topic: request.topic, accountId: accountId)
        else {
            logger?.warning("request \(request.method) for topic \(request.topic) does not belong to the active account, ignoring")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            let result = await requestService.process(request: request, context: context, session: session)
            emit(WCNRequestItem(requestId: request.id, result: result, session: session))
        }
    }

    private func emit(_ incoming: WCNRequestItem) {
        if case .rejected = incoming.result {
            return
        }
        if lockProvider.isLocked {
            queueLock.lock()
            queued.append(incoming)
            queueLock.unlock()
            logger?.info("app is locked, queued request id=\(incoming.requestId.string)")
        } else {
            requestSubject.send(incoming)
        }
    }

    private func flushQueue() {
        queueLock.lock()
        let pending = queued
        queued.removeAll()
        queueLock.unlock()
        pending.forEach { requestSubject.send($0) }
    }

    private func expire(requestId: RPCID) {
        queueLock.lock()
        queued.removeAll { $0.requestId == requestId }
        queueLock.unlock()
        expiredRequestSubject.send(requestId)
    }
}

extension WCNKit {
    enum KitError: Error {
        case noActiveAccount
    }
}

import Combine
import Foundation
import ReownWalletKit
import Testing
@testable import WalletCore

struct WCNKitTests {
    private let client = WCNSpySignClient()
    private let accounts = WCNStubAccountProvider(activeAccountId: "a1")
    private let lock = StubLockProvider(isLocked: false)
    private let parsers = WCNParserRegistry()
    private let directHandlers = WCNDirectHandlerRegistry()

    private func makeKit(storage: WCNSessionStorage) -> WCNKit {
        let responder = WCNResponder(signClient: client)
        let chainSupports = WCNChainSupportRegistry()
        chainSupports.register(WCNChainSupportFixtures.evmSupport())
        return WCNKit(
            signClient: client,
            sessionService: WCNSessionService(signClient: client, storage: storage, accountProvider: accounts),
            requestService: WCNRequestService(parsers: parsers, verifiers: WCNVerifierRegistry(), responder: responder),
            directHandlers: directHandlers,
            responder: responder,
            pairingService: WCNPairingService(signClient: client, proposalTimeout: 0.2),
            verifyService: WCNVerifyService(),
            namespaceBuilder: WCNNamespaceBuilder(registry: chainSupports),
            accountProvider: accounts,
            lockProvider: lock
        )
    }

    private func storedKit(topic: String = WCNTestFixtures.topic, accountId: String = "a1") throws -> (WCNKit, WCNSessionStorage) {
        let storage = try WCNSessionFixtures.storage()
        let session = try WCNSessionFixtures.session(topic: topic)
        client.sessions = [session]
        parsers.register(StubParser())
        let kit = makeKit(storage: storage)
        kit.start()
        try WCNSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: accountId)
        return (kit, storage)
    }

    private func collect<T>(_ publisher: AnyPublisher<T, Never>, into box: Box<[T]>) -> AnyCancellable {
        publisher.sink { box.value.append($0) }
    }

    @Test func requestOfActiveSessionIsPublished() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCNTestFixtures.request(), context: nil))
        try await waitUntil { box.value.count == 1 }

        let item = try #require(box.value.first)
        guard case .transaction = item.result else {
            Issue.record("expected transaction result")
            return
        }
        #expect(item.session.topic == WCNTestFixtures.topic)
    }

    @Test func requestOfForeignTopicIsIgnored() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        let foreign = try Request(topic: "unknown-topic", method: "eth_sendTransaction", params: AnyCodable([String]()), chainId: WalletConnectUtils.Blockchain("eip155:1")!)
        client.sessionRequestSubject.send((request: foreign, context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(box.value.isEmpty)
        #expect(client.calls.isEmpty)
    }

    @Test func requestOfOtherAccountSessionIsIgnored() async throws {
        let (kit, _) = try storedKit(accountId: "a2")
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCNTestFixtures.request(), context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(box.value.isEmpty)
    }

    @Test func lockedAppQueuesUntilUnlock() async throws {
        lock.isLocked = true
        let (kit, _) = try storedKit()
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCNTestFixtures.request(), context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(box.value.isEmpty)

        lock.isLocked = false
        try await waitUntil { box.value.count == 1 }
    }

    @Test func expirationDropsQueuedRequest() async throws {
        lock.isLocked = true
        let (kit, _) = try storedKit()
        let requests = Box<[WCNRequestItem]>([])
        let expired = Box<[RPCID]>([])
        let c1 = collect(kit.requestPublisher, into: requests)
        let c2 = collect(kit.expiredRequestPublisher, into: expired)
        defer { c1.cancel(); c2.cancel() }

        let request = try WCNTestFixtures.request()
        client.sessionRequestSubject.send((request: request, context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        client.requestExpirationSubject.send(request.id)
        lock.isLocked = false
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(requests.value.isEmpty)
        #expect(expired.value == [request.id])
    }

    @Test func pendingRequestsAreReplayedOnStart() async throws {
        let storage = try WCNSessionFixtures.storage()
        let session = try WCNSessionFixtures.session(topic: WCNTestFixtures.topic)
        client.sessions = [session]
        parsers.register(StubParser())
        try WCNSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: "a1")
        client.pendingRequests = [(request: try WCNTestFixtures.request(), context: nil)]
        let kit = makeKit(storage: storage)
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        kit.start()
        try await waitUntil { box.value.count == 1 }
    }

    @Test func approveStoresApprovedSnapshot() async throws {
        let storage = try WCNSessionFixtures.storage()
        let kit = makeKit(storage: storage)
        let proposal = try WCNPairingFixtures.proposal()
        let proposals = kit.blockchainProposals(for: proposal)
        #expect(proposals.map(\.chain.absoluteString) == ["eip155:1", "eip155:10"])

        try await kit.approve(proposal: proposal, selected: proposals)

        #expect(client.approvals.count == 1)
        #expect(client.approvals[0].proposalId == proposal.id)
        let stored = try storage.session(topic: "settled-\(proposal.id)")
        let record = try #require(stored)
        let accounts = try record.sessionNamespaces().accounts
        #expect(record.accountId == "a1")
        #expect(accounts == [WCNTestFixtures.approvedMainnet, WCNTestFixtures.approvedOptimism])
    }

    @Test func rejectForwardsToSignClient() async throws {
        let kit = makeKit(storage: try WCNSessionFixtures.storage())
        let proposal = try WCNPairingFixtures.proposal()
        try await kit.reject(proposal: proposal)
        #expect(client.rejectedProposalIds == [proposal.id])
    }

    @Test func proposalIsPublishedWithVerifyStateAndChains() async throws {
        let kit = makeKit(storage: try WCNSessionFixtures.storage())
        kit.start()
        let box = Box<[WCNProposalItem]>([])
        let cancellable = collect(kit.proposalPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionProposalSubject.send((proposal: try WCNPairingFixtures.proposal(), context: VerifyContext(origin: "https://react-app.walletconnect.com", validation: .valid)))
        try await waitUntil { box.value.count == 1 }

        let item = try #require(box.value.first)
        #expect(item.verifyState == .verified(origin: "https://react-app.walletconnect.com"))
        #expect(item.blockchainProposals.count == 2)
    }

    @Test func directRequestIsAnsweredWithoutPublishing() async throws {
        parsers.register(DirectStubParser())
        let handler = SpyDirectHandler()
        directHandlers.register(handler)
        let (kit, _) = try storedKit()
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCNTestFixtures.request(method: "wallet_switchEthereumChain"), context: nil))
        try await waitUntil { handler.responded == 1 }

        #expect(box.value.isEmpty)
    }

    @Test func unregisteredDirectRequestIsRefused() async throws {
        parsers.register(DirectStubParser())
        let (kit, _) = try storedKit()
        _ = kit

        let request = try WCNTestFixtures.request(method: "wallet_switchEthereumChain")
        client.sessionRequestSubject.send((request: request, context: nil))
        try await waitUntil { client.calls.count == 1 }

        #expect(client.calls[0].response == .error(JSONRPCError(code: 5101, message: "Unsupported wallet method.")))
    }

    @Test func pendingRequestsAreListedPerTopicAndReopenable() async throws {
        let storage = try WCNSessionFixtures.storage()
        let session = try WCNSessionFixtures.session(topic: WCNTestFixtures.topic)
        client.sessions = [session]
        parsers.register(StubParser())
        try WCNSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: "a1")
        let request = try WCNTestFixtures.request()
        let foreign = try Request(topic: "other", method: "eth_sendTransaction", params: AnyCodable([String]()), chainId: WalletConnectUtils.Blockchain("eip155:1")!)
        client.pendingRequests = [(request: request, context: nil), (request: foreign, context: nil)]
        let kit = makeKit(storage: storage)
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        #expect(kit.pendingRequests(topic: WCNTestFixtures.topic) == [WCNPendingRequestItem(id: request.id, method: "eth_sendTransaction")])

        kit.open(requestId: request.id)
        try await waitUntil { box.value.count == 1 }
        #expect(box.value.first?.requestId == request.id)
    }

    @Test func rejectAnswersUserRejected() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCNRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }
        client.sessionRequestSubject.send((request: try WCNTestFixtures.request(), context: nil))
        try await waitUntil { box.value.count == 1 }
        let item = try #require(box.value.first)

        try await kit.reject(item: item)

        #expect(client.calls.last?.response == .error(JSONRPCError(code: 5000, message: "User rejected.")))
    }

    private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 20_000_000)
        }
        #expect(condition())
    }
}

final class Box<T> {
    private let lock = NSLock()
    private var stored: T

    init(_ value: T) {
        stored = value
    }

    var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return stored
        }
        set {
            lock.lock()
            stored = newValue
            lock.unlock()
        }
    }
}

private final class StubLockProvider: IWCNLockProvider {
    private let subject: CurrentValueSubject<Bool, Never>

    init(isLocked: Bool) {
        subject = CurrentValueSubject(isLocked)
    }

    var isLocked: Bool {
        get { subject.value }
        set { subject.send(newValue) }
    }

    var isLockedPublisher: AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }
}

private final class DirectStubParser: IWCNParser {
    func parse(request: Request) throws -> WCNRequestPayload? {
        guard request.method == "wallet_switchEthereumChain" else { return nil }
        return WCNRequestPayload(request: request, kind: .direct, from: nil)
    }
}

private final class SpyDirectHandler: IWCNDirectHandler {
    private(set) var responded = 0

    func handles(_ payload: WCNRequestPayload) -> Bool { payload.kind == .direct }

    func respond(request _: WCNRequest, session _: WCNSessionInfo) async throws {
        responded += 1
    }
}

private final class StubParser: IWCNParser {
    func parse(request: Request) throws -> WCNRequestPayload? {
        guard request.method == "eth_sendTransaction" else { return nil }
        return WCNRequestPayload(request: request, kind: .transaction, from: WCNTestFixtures.address)
    }
}

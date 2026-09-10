import Combine
import Foundation
import ReownWalletKit
import Testing
@testable import WalletCore

struct WCKitTests {
    private let client = WCSpySignClient()
    private let accounts = WCStubAccountProvider(activeAccountId: "a1")
    private let lock = StubLockProvider(isLocked: false)
    private let foreground = WCStubForegroundProvider(isActive: true)
    private let parsers = WCParserRegistry()
    private let directHandlers = WCDirectHandlerRegistry()

    private func makeKit(storage: WCSessionStorage) -> WCKit {
        let responder = WCResponder(signClient: client)
        let chainSupports = WCChainSupportRegistry()
        chainSupports.register(WCChainSupportFixtures.evmSupport())
        return WCKit(
            signClient: client,
            sessionService: WCSessionService(signClient: client, storage: storage, accountProvider: accounts),
            requestService: WCRequestService(parsers: parsers, verifiers: WCVerifierRegistry(), responder: responder),
            directHandlers: directHandlers,
            responder: responder,
            pairingService: WCPairingService(signClient: client, proposalTimeout: 0.2),
            verifyService: WCVerifyService(),
            namespaceBuilder: WCNamespaceBuilder(registry: chainSupports),
            accountProvider: accounts,
            lockProvider: lock,
            foregroundProvider: foreground
        )
    }

    private func storedKit(topic: String = WCTestFixtures.topic, accountId: String = "a1") throws -> (WCKit, WCSessionStorage) {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: topic)
        client.sessions = [session]
        parsers.register(StubParser())
        let kit = makeKit(storage: storage)
        try WCSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: accountId)
        kit.start()
        return (kit, storage)
    }

    private func collect<T>(_ publisher: AnyPublisher<T, Never>, into box: Box<[T]>) -> AnyCancellable {
        publisher.sink { box.value.append($0) }
    }

    @Test func requestOfActiveSessionIsPublished() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCTestFixtures.request(), context: nil))
        try await waitUntil { box.value.count == 1 }

        let item = try #require(box.value.first)
        guard case .transaction = item.result else {
            Issue.record("expected transaction result")
            return
        }
        #expect(item.session.topic == WCTestFixtures.topic)
    }

    @Test func replayedRequestIsPublishedOnce() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        let request = try WCTestFixtures.request()
        client.sessionRequestSubject.send((request: request, context: nil))
        client.sessionRequestSubject.send((request: request, context: nil))
        try await waitUntil { box.value.count == 1 }
        try await Task.sleep(nanoseconds: 200_000_000)

        #expect(box.value.count == 1)
    }

    @Test func requestOfForeignTopicIsIgnored() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
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
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCTestFixtures.request(), context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(box.value.isEmpty)
    }

    @Test func lockedAppQueuesUntilUnlock() async throws {
        lock.isLocked = true
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCTestFixtures.request(), context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(box.value.isEmpty)

        lock.isLocked = false
        try await waitUntil { box.value.count == 1 }
    }

    @Test func expirationDropsQueuedRequest() async throws {
        lock.isLocked = true
        let (kit, _) = try storedKit()
        let requests = Box<[WCRequestItem]>([])
        let expired = Box<[RPCID]>([])
        let c1 = collect(kit.requestPublisher, into: requests)
        let c2 = collect(kit.expiredRequestPublisher, into: expired)
        defer { c1.cancel(); c2.cancel() }

        let request = try WCTestFixtures.request()
        client.sessionRequestSubject.send((request: request, context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        client.requestExpirationSubject.send(request.id)
        lock.isLocked = false
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(requests.value.isEmpty)
        #expect(expired.value == [request.id])
    }

    @Test func pendingRequestsAtStartAreNotShownButListed() async throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: WCTestFixtures.topic)
        client.sessions = [session]
        parsers.register(StubParser())
        try WCSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: "a1")
        let request = try WCTestFixtures.request()
        client.pendingRequests = [(request: request, context: nil)]
        let kit = makeKit(storage: storage)
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        kit.start()
        try await Task.sleep(nanoseconds: 200_000_000)

        // seeded at start: only counted, never popped up (points 7 and 8, cold start)
        #expect(box.value.isEmpty)
        #expect(kit.pendingRequests(topic: WCTestFixtures.topic) == [WCPendingRequestItem(id: request.id, method: "eth_sendTransaction")])
    }

    @Test func expiredPendingRequestsAreHiddenAndNotCounted() throws {
        let (kit, _) = try storedKit()
        var expired = try WCTestFixtures.request()
        expired.expiryTimestamp = 0
        var valid = try WCTestFixtures.request()
        valid.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + 3600
        var withoutDeadline = try WCTestFixtures.request()
        withoutDeadline.expiryTimestamp = nil
        client.pendingRequests = [(expired, nil), (valid, nil), (withoutDeadline, nil)]

        #expect(kit.pendingRequests(topic: WCTestFixtures.topic).map(\.id) == [valid.id, withoutDeadline.id])
        #expect(kit.pendingRequestCount == 2)
    }

    @Test func expiredPendingRequestCannotBeOpened() async throws {
        let (kit, _) = try storedKit()
        var expired = try WCTestFixtures.request()
        expired.expiryTimestamp = 0
        client.pendingRequests = [(expired, nil)]
        let requests = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: requests)
        defer { cancellable.cancel() }

        kit.open(requestId: expired.id)
        client.sessionRequestSubject.send((expired, nil))
        try await Task.sleep(nanoseconds: 150_000_000)

        #expect(requests.value.isEmpty)
        #expect(client.calls.isEmpty)
    }

    @Test func foregroundRefreshesPendingListsWithoutSdkExpirationEvent() throws {
        foreground.isActive = false
        let (kit, _) = try storedKit()
        var expired = try WCTestFixtures.request()
        expired.expiryTimestamp = 0
        client.pendingRequests = [(expired, nil)]
        let counts = Box<[Int]>([])
        let cancellable = kit.pendingRequestsPublisher.sink { counts.value.append(kit.pendingRequestCount) }
        defer { cancellable.cancel() }

        foreground.isActive = true

        #expect(counts.value == [0])
    }

    @MainActor @Test func timerRefreshesBadgeWithoutSdkExpirationEvent() async throws {
        let (kit, _) = try storedKit()
        var request = try WCTestFixtures.request()
        request.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + 3
        client.pendingRequests = [(request, nil)]
        let parsed = WCRequest(payload: WCRequestPayload(request: request, kind: .signMessage, from: nil), verdict: .pass, dAppName: "dApp")
        let expirationViewModel = WCRequestExpirationViewModel(request: parsed, updates: kit.pendingRequestsPublisher)
        let expirationStates = Box<[Bool]>([])
        let expirationCancellable = expirationViewModel.$isExpired.sink {
            #expect(Thread.isMainThread)
            expirationStates.value.append($0)
        }
        defer { expirationCancellable.cancel() }
        let counts = Box<[Int]>([])
        let cancellable = kit.pendingRequestsPublisher.sink { counts.value.append(kit.pendingRequestCount) }
        defer { cancellable.cancel() }
        try #require(kit.pendingRequestCount == 1)

        try await waitUntil(timeout: 5) { counts.value.last == 0 }

        #expect(kit.pendingRequests(topic: WCTestFixtures.topic).isEmpty)
        try await waitUntil { expirationViewModel.isExpired }
        #expect(expirationStates.value == [false, true])
        client.requestExpirationSubject.send(request.id)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(expirationStates.value == [false, true])
    }

    @MainActor @Test func expirationTimerDoesNotPollAfterLastDeadline() async throws {
        let (kit, _) = try storedKit()
        var request = try WCTestFixtures.request()
        request.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + 2
        client.pendingRequests = [(request, nil)]
        let counts = Box<[Int]>([])
        let cancellable = kit.pendingRequestsPublisher.sink { counts.value.append(kit.pendingRequestCount) }
        defer { cancellable.cancel() }

        try await waitUntil(timeout: 4) { counts.value.last == 0 }
        // Let the expiration callback finish replanning, then observe a quiet interval longer than a tick.
        try await Task.sleep(nanoseconds: 100_000_000)
        let readCount = client.pendingRequestsReadCount
        try await Task.sleep(nanoseconds: 1_200_000_000)

        #expect(client.pendingRequestsReadCount == readCount)
    }

    @MainActor @Test(arguments: [nil, UInt64(0)])
    func noFutureDeadlineDoesNotStartPolling(expiryTimestamp: UInt64?) async throws {
        let (kit, _) = try storedKit()
        var request = try WCTestFixtures.request()
        request.expiryTimestamp = expiryTimestamp
        client.pendingRequests = [(request, nil)]
        try await Task.sleep(nanoseconds: 100_000_000)
        let readCount = client.pendingRequestsReadCount
        try await Task.sleep(nanoseconds: 1_200_000_000)

        #expect(client.pendingRequestsReadCount == readCount)
        withExtendedLifetime(kit) {}
    }

    @MainActor @Test func newEarlierDeadlineReplacesTimerAndSchedulesNext() async throws {
        let (kit, _) = try storedKit()
        let now = UInt64(Date().timeIntervalSince1970)
        var later = try WCTestFixtures.request()
        later.expiryTimestamp = now + 4
        client.pendingRequests = [(later, nil)]
        // Allow the initial schedule to be installed before a nearer deadline arrives.
        try await Task.sleep(nanoseconds: 100_000_000)
        var earlier = try WCTestFixtures.request()
        earlier.expiryTimestamp = now + 2
        client.pendingRequests = [(later, nil), (earlier, nil)]
        let counts = Box<[Int]>([])
        let cancellable = kit.pendingRequestsPublisher.sink { counts.value.append(kit.pendingRequestCount) }
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((earlier, nil))
        try await waitUntil(timeout: 6) { counts.value.last == 0 }

        #expect(counts.value == [2, 1, 0])
    }

    @MainActor @Test func sdkRemovalCancelsScheduledExpiration() async throws {
        let (kit, _) = try storedKit()
        var request = try WCTestFixtures.request()
        request.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + 2
        client.pendingRequests = [(request, nil)]
        try await Task.sleep(nanoseconds: 100_000_000)
        let updates = Box<[Void]>([])
        let cancellable = collect(kit.pendingRequestsPublisher, into: updates)
        defer { cancellable.cancel() }

        client.pendingRequests = []
        client.requestExpirationSubject.send(request.id)
        try await Task.sleep(nanoseconds: 2_200_000_000)

        #expect(updates.value.count == 1)
        withExtendedLifetime(kit) {}
    }

    @MainActor @Test func backgroundCancelsTimerAndForegroundRefreshesExpiredList() async throws {
        let (kit, _) = try storedKit()
        var request = try WCTestFixtures.request()
        request.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + 2
        client.pendingRequests = [(request, nil)]
        let parsed = WCRequest(payload: WCRequestPayload(request: request, kind: .transaction, from: nil), verdict: .pass, dAppName: "dApp")
        let expirationViewModel = WCRequestExpirationViewModel(request: parsed, updates: kit.pendingRequestsPublisher)
        try await Task.sleep(nanoseconds: 100_000_000)
        let counts = Box<[Int]>([])
        let cancellable = kit.pendingRequestsPublisher.sink { counts.value.append(kit.pendingRequestCount) }
        defer { cancellable.cancel() }

        foreground.isActive = false
        try await Task.sleep(nanoseconds: 100_000_000)
        let readCount = client.pendingRequestsReadCount
        try await Task.sleep(nanoseconds: 2_200_000_000)
        #expect(client.pendingRequestsReadCount == readCount)
        #expect(expirationViewModel.isExpired == false)

        foreground.isActive = true
        #expect(counts.value.last == 0)
        #expect(kit.pendingRequests(topic: WCTestFixtures.topic).isEmpty)
        try await waitUntil { expirationViewModel.isExpired }
    }

    @MainActor @Test func requestExpiringInBackgroundDoesNotOccupyPresentationSlot() async throws {
        foreground.isActive = false
        let (kit, _) = try storedKit()
        var request = try WCTestFixtures.request()
        request.expiryTimestamp = UInt64(Date().timeIntervalSince1970) + 2
        let requests = Box<[WCRequestItem]>([])
        let cancellable = kit.requestPublisher.receive(on: DispatchQueue.main).sink { requests.value.append($0) }
        defer { cancellable.cancel() }
        client.sessionRequestSubject.send((request, nil))

        try await waitUntil(timeout: 4) { WCRequest.isExpired(expiryTimestamp: request.expiryTimestamp) }
        foreground.isActive = true
        let valid = try WCTestFixtures.request()
        client.sessionRequestSubject.send((valid, nil))
        try await waitUntil { requests.value.count == 1 }

        #expect(requests.value.first?.requestId == valid.id)
    }

    @Test func backgroundRequestIsShownOnForeground() async throws {
        foreground.isActive = false
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCTestFixtures.request(), context: nil))
        try await Task.sleep(nanoseconds: 150_000_000)
        #expect(box.value.isEmpty)

        foreground.isActive = true
        try await waitUntil { box.value.count == 1 }
    }

    @Test func openedRequestIsNotRepresentedOnSdkReplay() async throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: WCTestFixtures.topic)
        client.sessions = [session]
        parsers.register(StubParser())
        try WCSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: "a1")
        let request = try WCTestFixtures.request()
        client.pendingRequests = [(request: request, context: nil)]
        let kit = makeKit(storage: storage)
        kit.start()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        kit.open(requestId: request.id)
        try await waitUntil { box.value.count == 1 }

        // reown replays the pending request on reconnect; opening it from the list must not stack a second sheet
        client.sessionRequestSubject.send((request: request, context: nil))
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(box.value.count == 1)
    }

    @Test func newRequestSurfacesWhenSdkReplaysOldPending() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        let first = try WCTestFixtures.request()
        client.pendingRequests = [(request: first, context: nil)]
        client.sessionRequestSubject.send((request: first, context: nil))
        try await waitUntil { box.value.count == 1 }
        #expect(box.value.first?.requestId == first.id)

        // a genuinely new request arrives but reown replays the old head; it becomes active
        let second = try WCTestFixtures.request()
        client.pendingRequests = [(request: first, context: nil), (request: second, context: nil)]
        client.sessionRequestSubject.send((request: first, context: nil))
        try await Task.sleep(nanoseconds: 200_000_000)
        // one sheet at a time: it shows only after the first is dismissed
        #expect(box.value.count == 1)
        kit.notifyRequestDismissed()
        try await waitUntil { box.value.count == 2 }
        #expect(box.value.last?.requestId == second.id)
    }

    @Test func secondRequestWaitsUntilFirstIsDismissed() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        let first = try WCTestFixtures.request()
        let second = try WCTestFixtures.request()
        client.pendingRequests = [(request: first, context: nil)]
        client.sessionRequestSubject.send((request: first, context: nil))
        try await waitUntil { box.value.count == 1 }
        #expect(box.value.first?.requestId == first.id)

        // a second request arrives while the first sheet is up: it must not stack
        client.pendingRequests = [(request: first, context: nil), (request: second, context: nil)]
        client.sessionRequestSubject.send((request: second, context: nil))
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(box.value.count == 1)

        // dismissing the first releases the slot and the second appears
        kit.notifyRequestDismissed()
        try await waitUntil { box.value.count == 2 }
        #expect(box.value.last?.requestId == second.id)
    }

    @Test func onlyLastBackgroundRequestIsShown() async throws {
        foreground.isActive = false
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        let first = try WCTestFixtures.request()
        let second = try WCTestFixtures.request()
        client.sessionRequestSubject.send((request: first, context: nil))
        client.sessionRequestSubject.send((request: second, context: nil))
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(box.value.isEmpty)

        foreground.isActive = true
        try await waitUntil { box.value.count == 1 }
        #expect(box.value.first?.requestId == second.id)
    }

    @Test func approveStoresApprovedSnapshot() async throws {
        let storage = try WCSessionFixtures.storage()
        let kit = makeKit(storage: storage)
        let proposal = try WCPairingFixtures.proposal()
        let proposals = kit.blockchainProposals(for: proposal)
        #expect(proposals.map(\.chain.absoluteString) == ["eip155:1", "eip155:10"])

        try await kit.approve(proposal: proposal, selected: proposals)

        #expect(client.approvals.count == 1)
        #expect(client.approvals[0].proposalId == proposal.id)
        let stored = try storage.session(topic: "settled-\(proposal.id)")
        let record = try #require(stored)
        let accounts = try record.sessionNamespaces().accounts
        #expect(record.accountId == "a1")
        #expect(accounts == [WCTestFixtures.approvedMainnet, WCTestFixtures.approvedOptimism])
    }

    @Test func rejectForwardsToSignClient() async throws {
        let kit = makeKit(storage: try WCSessionFixtures.storage())
        let proposal = try WCPairingFixtures.proposal()
        try await kit.reject(proposal: proposal)
        #expect(client.rejectedProposalIds == [proposal.id])
    }

    @Test func proposalIsPublishedWithVerifyStateAndChains() async throws {
        let kit = makeKit(storage: try WCSessionFixtures.storage())
        kit.start()
        let box = Box<[WCProposalItem]>([])
        let cancellable = collect(kit.proposalPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionProposalSubject.send((proposal: try WCPairingFixtures.proposal(), context: VerifyContext(origin: "https://react-app.walletconnect.com", validation: .valid)))
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
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        client.sessionRequestSubject.send((request: try WCTestFixtures.request(method: "wallet_switchEthereumChain"), context: nil))
        try await waitUntil { handler.responded == 1 }

        #expect(box.value.isEmpty)
    }

    @Test func unregisteredDirectRequestIsRefused() async throws {
        parsers.register(DirectStubParser())
        let (kit, _) = try storedKit()
        _ = kit

        let request = try WCTestFixtures.request(method: "wallet_switchEthereumChain")
        client.sessionRequestSubject.send((request: request, context: nil))
        try await waitUntil { client.calls.count == 1 }

        #expect(client.calls[0].response == .error(JSONRPCError(code: 5101, message: "Unsupported wallet method.")))
    }

    @Test func pendingRequestsAreListedPerTopicAndReopenable() async throws {
        let storage = try WCSessionFixtures.storage()
        let session = try WCSessionFixtures.session(topic: WCTestFixtures.topic)
        client.sessions = [session]
        parsers.register(StubParser())
        try WCSessionService(signClient: client, storage: storage, accountProvider: accounts).store(session: session, accountId: "a1")
        let request = try WCTestFixtures.request()
        let foreign = try Request(topic: "other", method: "eth_sendTransaction", params: AnyCodable([String]()), chainId: WalletConnectUtils.Blockchain("eip155:1")!)
        client.pendingRequests = [(request: request, context: nil), (request: foreign, context: nil)]
        let kit = makeKit(storage: storage)
        kit.start()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }

        #expect(kit.pendingRequests(topic: WCTestFixtures.topic) == [WCPendingRequestItem(id: request.id, method: "eth_sendTransaction")])

        kit.open(requestId: request.id)
        try await waitUntil { box.value.count == 1 }
        #expect(box.value.first?.requestId == request.id)
    }

    @Test func rejectAnswersUserRejected() async throws {
        let (kit, _) = try storedKit()
        let box = Box<[WCRequestItem]>([])
        let cancellable = collect(kit.requestPublisher, into: box)
        defer { cancellable.cancel() }
        client.sessionRequestSubject.send((request: try WCTestFixtures.request(), context: nil))
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

private final class StubLockProvider: IWCLockProvider {
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

private final class DirectStubParser: IWCParser {
    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.method == "wallet_switchEthereumChain" else { return nil }
        return WCRequestPayload(request: request, kind: .direct, from: nil)
    }
}

private final class SpyDirectHandler: IWCDirectHandler {
    private(set) var responded = 0

    func handles(_ payload: WCRequestPayload) -> Bool { payload.kind == .direct }

    func respond(request _: WCRequest, session _: WCSessionInfo) async throws {
        responded += 1
    }
}

private final class StubParser: IWCParser {
    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.method == "eth_sendTransaction" else { return nil }
        return WCRequestPayload(request: request, kind: .transaction, from: WCTestFixtures.address)
    }
}

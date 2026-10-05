import Combine
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCManagerTests {
    private func manager(storage: WCSessionStorage, factory: SpyKitFactory) -> WCManager {
        WCManager(storage: storage, kitFactory: factory, chainSupportRegistry: WCChainSupportRegistry(), sendHandlerRegistry: WCSendHandlerRegistry(), directHandlerRegistry: WCDirectHandlerRegistry(), signMessageHandlerRegistry: WCSignMessageHandlerRegistry())
    }

    @Test func startsEagerlyWhenSessionsArePersisted() throws {
        let storage = try WCSessionFixtures.storage()
        let namespaces = try WCSessionNamespaces(sessionNamespaces: WCSessionFixtures.session(topic: "t1").namespaces)
        try storage.save(session: WCSessionRecord(topic: "t1", accountId: "a1", dAppName: "d", namespaces: namespaces))
        let factory = SpyKitFactory()

        let manager = manager(storage: storage, factory: factory)
        #expect(factory.makeCount == 0)

        manager.start()

        #expect(factory.makeCount == 1)
        #expect(manager.startedKit != nil)
    }

    @Test func staysLazyWithoutSessionsAndBuildsOnce() throws {
        let factory = SpyKitFactory()
        let manager = manager(storage: try WCSessionFixtures.storage(), factory: factory)
        manager.start()

        #expect(factory.makeCount == 0)
        #expect(manager.startedKit == nil)

        let first = try manager.kit()
        let second = try manager.kit()

        #expect(factory.makeCount == 1)
        #expect(first === second)
        #expect(manager.startedKit === first)
    }
}

private final class SpyKitFactory: IWCKitFactory {
    private(set) var makeCount = 0

    func makeKit() throws -> WCKit {
        makeCount += 1
        let client = WCSpySignClient()
        let accounts = WCStubAccountProvider(activeAccountId: "a1")
        let responder = WCResponder(signClient: client)
        return WCKit(
            signClient: client,
            sessionService: WCSessionService(signClient: client, storage: try WCSessionFixtures.storage(), accountProvider: accounts),
            requestService: WCRequestService(parsers: WCParserRegistry(), verifiers: WCVerifierRegistry(), responder: responder),
            directHandlers: WCDirectHandlerRegistry(),
            responder: responder,
            pairingService: WCPairingService(signClient: client),
            verifyService: WCVerifyService(),
            namespaceBuilder: WCNamespaceBuilder(registry: WCChainSupportRegistry()),
            accountProvider: accounts,
            lockProvider: NeverLocked(),
            foregroundProvider: WCStubForegroundProvider(isActive: true)
        )
    }
}

private final class NeverLocked: IWCLockProvider {
    var isLocked: Bool { false }
    var isLockedPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
}

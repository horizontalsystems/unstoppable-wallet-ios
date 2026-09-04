import Combine
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNManagerTests {
    private func manager(storage: WCNSessionStorage, factory: SpyKitFactory) -> WCNManager {
        WCNManager(storage: storage, kitFactory: factory, chainSupportRegistry: WCNChainSupportRegistry(), sendHandlerRegistry: WCNSendHandlerRegistry(), directHandlerRegistry: WCNDirectHandlerRegistry(), signMessageHandlerRegistry: WCNSignMessageHandlerRegistry())
    }

    @Test func startsEagerlyWhenSessionsArePersisted() throws {
        let storage = try WCNSessionFixtures.storage()
        let namespaces = try WCNSessionNamespaces(sessionNamespaces: WCNSessionFixtures.session(topic: "t1").namespaces)
        try storage.save(session: WCNSessionRecord(topic: "t1", accountId: "a1", dAppName: "d", namespaces: namespaces))
        let factory = SpyKitFactory()

        let manager = manager(storage: storage, factory: factory)
        #expect(factory.makeCount == 0)

        manager.start()

        #expect(factory.makeCount == 1)
        #expect(manager.startedKit != nil)
    }

    @Test func staysLazyWithoutSessionsAndBuildsOnce() throws {
        let factory = SpyKitFactory()
        let manager = manager(storage: try WCNSessionFixtures.storage(), factory: factory)
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

private final class SpyKitFactory: IWCNKitFactory {
    private(set) var makeCount = 0

    func makeKit() throws -> WCNKit {
        makeCount += 1
        let client = WCNSpySignClient()
        let accounts = WCNStubAccountProvider(activeAccountId: "a1")
        let responder = WCNResponder(signClient: client)
        return WCNKit(
            signClient: client,
            sessionService: WCNSessionService(signClient: client, storage: try WCNSessionFixtures.storage(), accountProvider: accounts),
            requestService: WCNRequestService(parsers: WCNParserRegistry(), verifiers: WCNVerifierRegistry(), responder: responder),
            directHandlers: WCNDirectHandlerRegistry(),
            responder: responder,
            pairingService: WCNPairingService(signClient: client),
            verifyService: WCNVerifyService(),
            namespaceBuilder: WCNNamespaceBuilder(registry: WCNChainSupportRegistry()),
            accountProvider: accounts,
            lockProvider: NeverLocked()
        )
    }
}

private final class NeverLocked: IWCNLockProvider {
    var isLocked: Bool { false }
    var isLockedPublisher: AnyPublisher<Bool, Never> { Just(false).eraseToAnyPublisher() }
}

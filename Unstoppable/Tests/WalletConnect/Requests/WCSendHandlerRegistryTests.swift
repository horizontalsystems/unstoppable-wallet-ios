import MarketKit
import Testing
@testable import WalletCore

// WCSendHandlerProvider.registry is process-wide state, so these tests must not run in parallel
@Suite(.serialized)
struct WCSendHandlerRegistryTests {
    private func request() throws -> WCRequest {
        try WCRequest(payload: WCStubRequestPayload.make(), verdict: .pass, dAppName: "dApp")
    }

    @Test func firstMatchingFactoryWins() throws {
        let registry = WCSendHandlerRegistry()
        let skipping = StubFactory(handles: false)
        let matching = StubFactory(handles: true)
        registry.register(skipping)
        registry.register(matching)

        let request = try request()
        let handler = registry.handler(request: request, inner: .zcashMigration)

        #expect(handler != nil)
        #expect(skipping.calls == 1)
        #expect(matching.calls == 1)
    }

    @Test func emptyRegistryYieldsNil() throws {
        let registry = WCSendHandlerRegistry()
        let request = try request()
        let handler = registry.handler(request: request, inner: .zcashMigration)
        #expect(handler == nil)
    }

    @Test func providerMatchesOnlyWalletConnectNewCase() throws {
        let registry = WCSendHandlerRegistry()
        let factory = StubFactory(handles: true)
        registry.register(factory)
        WCSendHandlerProvider.registry = registry
        defer { WCSendHandlerProvider.registry = nil }

        let unrelated = WCSendHandlerProvider.instance(sendData: .zcashMigration)
        #expect(unrelated == nil)
        #expect(factory.calls == 0)

        let request = try request()
        let handler = WCSendHandlerProvider.instance(sendData: .walletConnect(inner: nil, request: request))
        #expect(handler != nil)
        #expect(factory.calls == 1)
    }

    @Test func providerWithoutRegistryYieldsNil() throws {
        WCSendHandlerProvider.registry = nil
        let request = try request()
        let handler = WCSendHandlerProvider.instance(sendData: .walletConnect(inner: .zcashMigration, request: request))
        #expect(handler == nil)
    }
}

private final class StubFactory: IWCSendHandlerFactory {
    private let handles: Bool
    private(set) var calls = 0

    init(handles: Bool) {
        self.handles = handles
    }

    func handler(request _: WCRequest, inner _: SendData?) -> ISendHandler? {
        calls += 1
        return handles ? StubHandler() : nil
    }
}

private final class StubHandler: ISendHandler {
    var baseToken: MarketKit.Token { fatalError("not used") }
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData { fatalError("not used") }
    func send(data _: ISendData) async throws {}
}

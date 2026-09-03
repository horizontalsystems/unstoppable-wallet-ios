import MarketKit
import Testing
@testable import WalletCore

// WCNSendHandlerProvider.registry is process-wide state, so these tests must not run in parallel
@Suite(.serialized)
struct WCNSendHandlerRegistryTests {
    private func request() throws -> WCNRequest {
        try WCNRequest(payload: WCNStubRequestPayload.make(), verdict: .pass, dAppName: "dApp")
    }

    @Test func firstMatchingFactoryWins() throws {
        let registry = WCNSendHandlerRegistry()
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
        let registry = WCNSendHandlerRegistry()
        let request = try request()
        let handler = registry.handler(request: request, inner: .zcashMigration)
        #expect(handler == nil)
    }

    @Test func providerMatchesOnlyWalletConnectNewCase() throws {
        let registry = WCNSendHandlerRegistry()
        let factory = StubFactory(handles: true)
        registry.register(factory)
        WCNSendHandlerProvider.registry = registry
        defer { WCNSendHandlerProvider.registry = nil }

        let unrelated = WCNSendHandlerProvider.instance(sendData: .zcashMigration)
        #expect(unrelated == nil)
        #expect(factory.calls == 0)

        let request = try request()
        let handler = WCNSendHandlerProvider.instance(sendData: .walletConnectNew(inner: nil, request: request))
        #expect(handler != nil)
        #expect(factory.calls == 1)
    }

    @Test func providerWithoutRegistryYieldsNil() throws {
        WCNSendHandlerProvider.registry = nil
        let request = try request()
        let handler = WCNSendHandlerProvider.instance(sendData: .walletConnectNew(inner: .zcashMigration, request: request))
        #expect(handler == nil)
    }
}

private final class StubFactory: IWCNSendHandlerFactory {
    private let handles: Bool
    private(set) var calls = 0

    init(handles: Bool) {
        self.handles = handles
    }

    func handler(request _: WCNRequest, inner _: SendData?) -> ISendHandler? {
        calls += 1
        return handles ? StubHandler() : nil
    }
}

private final class StubHandler: ISendHandler {
    var baseToken: MarketKit.Token { fatalError("not used") }
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData { fatalError("not used") }
    func send(data _: ISendData) async throws {}
}

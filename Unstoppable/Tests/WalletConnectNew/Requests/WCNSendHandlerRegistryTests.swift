import Testing
@testable import WalletCore

struct WCNSendHandlerRegistryTests {
    private func request() throws -> WCNRequest {
        try WCNRequest(parsed: WCNStubParsedRequest.make(), verdict: .pass, dAppName: "dApp")
    }

    @Test func firstMatchingFactoryWins() throws {
        let registry = WCNSendHandlerRegistry()
        let skipping = StubFactory(handles: false)
        let matching = StubFactory(handles: true)
        registry.register(skipping)
        registry.register(matching)

        let handler = registry.handler(request: try request(), inner: .zcashMigration)

        #expect(handler != nil)
        #expect(skipping.calls == 1)
        #expect(matching.calls == 1)
    }

    @Test func emptyRegistryYieldsNil() throws {
        let registry = WCNSendHandlerRegistry()
        #expect(registry.handler(request: try request(), inner: .zcashMigration) == nil)
    }

    @Test func providerMatchesOnlyWalletConnectNewCase() throws {
        let registry = WCNSendHandlerRegistry()
        let factory = StubFactory(handles: true)
        registry.register(factory)
        WCNSendHandlerProvider.registry = registry
        defer { WCNSendHandlerProvider.registry = nil }

        #expect(WCNSendHandlerProvider.instance(sendData: .zcashMigration) == nil)
        #expect(factory.calls == 0)

        let handler = WCNSendHandlerProvider.instance(sendData: .walletConnectNew(inner: .zcashMigration, request: try request()))
        #expect(handler != nil)
        #expect(factory.calls == 1)
    }

    @Test func providerWithoutRegistryYieldsNil() throws {
        WCNSendHandlerProvider.registry = nil
        #expect(WCNSendHandlerProvider.instance(sendData: .walletConnectNew(inner: .zcashMigration, request: try request())) == nil)
    }
}

private final class StubFactory: IWCNSendHandlerFactory {
    private let handles: Bool
    private(set) var calls = 0

    init(handles: Bool) {
        self.handles = handles
    }

    func handler(request _: WCNRequest, inner _: SendData) -> ISendHandler? {
        calls += 1
        return handles ? StubHandler() : nil
    }
}

private final class StubHandler: ISendHandler {
    var baseToken: MarketKit.Token { fatalError("not used") }
    func sendData(transactionSettings _: TransactionSettings?) async throws -> ISendData { fatalError("not used") }
    func send(data _: ISendData) async throws {}
}

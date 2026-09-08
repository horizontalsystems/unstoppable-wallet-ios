import Testing
import WalletConnectSign
@testable import WalletCore

struct WCParserRegistryTests {
    @Test func unsupportedMethodWhenNoParserClaims() throws {
        let registry = WCParserRegistry()
        registry.register(StubParser(method: "personal_sign"))
        let request = try WCTestFixtures.request(method: "eth_sendTransaction")

        #expect(throws: WCParserRegistry.ParsingError.unsupportedMethod("eth_sendTransaction")) {
            try registry.parse(request: request)
        }
    }

    @Test func firstClaimingParserWins() throws {
        let registry = WCParserRegistry()
        let other = StubParser(method: "personal_sign")
        let first = StubParser(method: "eth_sendTransaction")
        let second = StubParser(method: "eth_sendTransaction")
        registry.register(other)
        registry.register(first)
        registry.register(second)

        let payload = try registry.parse(request: WCTestFixtures.request(method: "eth_sendTransaction"))

        #expect(payload.method == "eth_sendTransaction")
        #expect(first.parseCount == 1)
        #expect(second.parseCount == 0)
    }

    @Test func malformedRequestStopsChain() throws {
        let registry = WCParserRegistry()
        let broken = StubParser(method: "eth_sendTransaction", error: StubParser.Malformed())
        let fallback = StubParser(method: "eth_sendTransaction")
        registry.register(broken)
        registry.register(fallback)
        let request = try WCTestFixtures.request(method: "eth_sendTransaction")

        #expect(throws: StubParser.Malformed.self) {
            try registry.parse(request: request)
        }
        #expect(fallback.parseCount == 0)
    }

    @Test func parsedCarriesRequestIdentity() throws {
        let request = try WCTestFixtures.request(method: "personal_sign", chainId: "eip155:10")
        let payload = WCRequestPayload(request: request, kind: .signMessage, from: WCTestFixtures.address)

        #expect(payload.id == request.id)
        #expect(payload.topic == request.topic)
        #expect(payload.chainId.absoluteString == "eip155:10")
        #expect(payload.kind == .signMessage)
        #expect(payload.to == nil)
        #expect(payload.value == nil)
        #expect(payload.makeSendData() == nil)
    }
}

private final class StubParser: IWCParser {
    struct Malformed: Error {}

    private let method: String
    private let error: Error?
    private(set) var parseCount = 0

    init(method: String, error: Error? = nil) {
        self.method = method
        self.error = error
    }

    func parse(request: Request) throws -> WCRequestPayload? {
        guard request.method == method else { return nil }
        parseCount += 1
        if let error { throw error }
        return WCRequestPayload(request: request, kind: .transaction, from: nil)
    }
}

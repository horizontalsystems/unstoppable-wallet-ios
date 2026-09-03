import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNParserRegistryTests {
    @Test func unsupportedMethodWhenNoParserClaims() throws {
        let registry = WCNParserRegistry()
        registry.register(StubParser(method: "personal_sign"))
        let request = try WCNTestFixtures.request(method: "eth_sendTransaction")

        #expect(throws: WCNParserRegistry.ParsingError.unsupportedMethod("eth_sendTransaction")) {
            try registry.parse(request: request)
        }
    }

    @Test func firstClaimingParserWins() throws {
        let registry = WCNParserRegistry()
        let other = StubParser(method: "personal_sign")
        let first = StubParser(method: "eth_sendTransaction")
        let second = StubParser(method: "eth_sendTransaction")
        registry.register(other)
        registry.register(first)
        registry.register(second)

        let parsed = try registry.parse(request: WCNTestFixtures.request(method: "eth_sendTransaction"))

        #expect(parsed.method == "eth_sendTransaction")
        #expect(first.parseCount == 1)
        #expect(second.parseCount == 0)
    }

    @Test func malformedRequestStopsChain() throws {
        let registry = WCNParserRegistry()
        let broken = StubParser(method: "eth_sendTransaction", error: StubParser.Malformed())
        let fallback = StubParser(method: "eth_sendTransaction")
        registry.register(broken)
        registry.register(fallback)
        let request = try WCNTestFixtures.request(method: "eth_sendTransaction")

        #expect(throws: StubParser.Malformed.self) {
            try registry.parse(request: request)
        }
        #expect(fallback.parseCount == 0)
    }

    @Test func parsedCarriesRequestIdentity() throws {
        let request = try WCNTestFixtures.request(method: "personal_sign", chainId: "eip155:10")
        let parsed = WCNParsedRequest(request: request, kind: .signMessage, from: WCNTestFixtures.address)

        #expect(parsed.id == request.id)
        #expect(parsed.topic == request.topic)
        #expect(parsed.chainId.absoluteString == "eip155:10")
        #expect(parsed.kind == .signMessage)
        #expect(parsed.to == nil)
        #expect(parsed.value == nil)
        #expect(parsed.makeSendData() == nil)
    }
}

private final class StubParser: IWCNParser {
    struct Malformed: Error {}

    private let method: String
    private let error: Error?
    private(set) var parseCount = 0

    init(method: String, error: Error? = nil) {
        self.method = method
        self.error = error
    }

    func parse(request: Request) throws -> WCNParsedRequest? {
        guard request.method == method else { return nil }
        parseCount += 1
        if let error { throw error }
        return WCNParsedRequest(request: request, kind: .transaction, from: nil)
    }
}

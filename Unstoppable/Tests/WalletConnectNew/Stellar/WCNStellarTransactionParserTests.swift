import Testing
@testable import WalletCore

struct WCNStellarTransactionParserTests {
    private let parser = WCNStellarTransactionParser()

    @Test func parsesEnvelopeAndExtractsSourceAccount() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let request = try WCNStellarFixtures.request(params: ["xdr": envelope.xdr])

        let result = try parser.parse(request: request)
        let payload = try #require(result as? WCNStellarTransactionPayload)

        #expect(payload.xdr == envelope.xdr)
        #expect(payload.from == envelope.sourceAccountId)
        #expect(payload.kind == .transaction)
        #expect(payload.isSignOnly == false)
        #expect(payload.makeSendData() == nil)
    }

    @Test func signMethodIsSignOnly() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let request = try WCNStellarFixtures.request(method: WCNStellarTransactionPayload.signMethod, params: ["xdr": envelope.xdr])
        let result = try parser.parse(request: request)
        let payload = try #require(result)
        #expect(payload.isSignOnly)
    }

    @Test func ignoresOtherNamespaceAndMethods() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let evm = try WCNStellarFixtures.request(chainId: "eip155:1", params: ["xdr": envelope.xdr])
        let other = try WCNStellarFixtures.request(method: "stellar_getAccounts", params: ["xdr": envelope.xdr])

        let evmResult = try parser.parse(request: evm)
        let otherResult = try parser.parse(request: other)
        #expect(evmResult == nil)
        #expect(otherResult == nil)
    }

    @Test func missingXdrIsMalformed() throws {
        let request = try WCNStellarFixtures.request(params: ["foo": "bar"])
        #expect(throws: WCNStellarTransactionParser.ParsingError.malformedParams) {
            try parser.parse(request: request)
        }
    }

    @Test func invalidXdrIsRejected() throws {
        let request = try WCNStellarFixtures.request(params: ["xdr": "not-an-envelope"])
        #expect(throws: WCNStellarTransactionParser.ParsingError.invalidEnvelope) {
            try parser.parse(request: request)
        }
    }
}

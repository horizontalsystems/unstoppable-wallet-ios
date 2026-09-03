import Testing
@testable import WalletCore

struct WCNStellarTransactionParserTests {
    private let parser = WCNStellarTransactionParser()

    @Test func parsesEnvelopeAndExtractsSourceAccount() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let request = try WCNStellarFixtures.request(params: ["xdr": envelope.xdr])

        let result = try parser.parse(request: request)
        let parsed = try #require(result as? WCNStellarTransactionParsed)

        #expect(parsed.xdr == envelope.xdr)
        #expect(parsed.from == envelope.sourceAccountId)
        #expect(parsed.kind == .transaction)
        #expect(parsed.isSignOnly == false)
        #expect(parsed.makeSendData() == nil)
    }

    @Test func signMethodIsSignOnly() throws {
        let envelope = try WCNStellarFixtures.envelope()
        let request = try WCNStellarFixtures.request(method: WCNStellarTransactionParsed.signMethod, params: ["xdr": envelope.xdr])
        let result = try parser.parse(request: request)
        let parsed = try #require(result)
        #expect(parsed.isSignOnly)
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

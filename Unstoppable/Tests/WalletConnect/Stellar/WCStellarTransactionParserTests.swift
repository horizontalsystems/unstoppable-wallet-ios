import Testing
@testable import WalletCore

struct WCStellarTransactionParserTests {
    private let parser = WCStellarTransactionParser()

    @Test func parsesEnvelopeAndExtractsSourceAccount() throws {
        let envelope = try WCStellarFixtures.envelope()
        let request = try WCStellarFixtures.request(params: ["xdr": envelope.xdr])

        let result = try parser.parse(request: request)
        let payload = try #require(result as? WCStellarTransactionPayload)

        #expect(payload.xdr == envelope.xdr)
        #expect(payload.from == envelope.sourceAccountId)
        #expect(payload.kind == .transaction)
        #expect(payload.isSignOnly == false)
        #expect(payload.makeSendData() == nil)
    }

    @Test func signMethodIsSignOnly() throws {
        let envelope = try WCStellarFixtures.envelope()
        let request = try WCStellarFixtures.request(method: WCStellarTransactionPayload.signMethod, params: ["xdr": envelope.xdr])
        let result = try parser.parse(request: request)
        let payload = try #require(result)
        #expect(payload.isSignOnly)
    }

    @Test func ignoresOtherNamespaceAndMethods() throws {
        let envelope = try WCStellarFixtures.envelope()
        let evm = try WCStellarFixtures.request(chainId: "eip155:1", params: ["xdr": envelope.xdr])
        let other = try WCStellarFixtures.request(method: "stellar_getAccounts", params: ["xdr": envelope.xdr])

        let evmResult = try parser.parse(request: evm)
        let otherResult = try parser.parse(request: other)
        #expect(evmResult == nil)
        #expect(otherResult == nil)
    }

    @Test func missingXdrIsMalformed() throws {
        let request = try WCStellarFixtures.request(params: ["foo": "bar"])
        #expect(throws: WCStellarTransactionParser.ParsingError.malformedParams) {
            try parser.parse(request: request)
        }
    }

    @Test func invalidXdrIsRejected() throws {
        let request = try WCStellarFixtures.request(params: ["xdr": "not-an-envelope"])
        #expect(throws: WCStellarTransactionParser.ParsingError.invalidEnvelope) {
            try parser.parse(request: request)
        }
    }
}

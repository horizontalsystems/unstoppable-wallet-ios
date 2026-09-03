import Foundation
import SolanaKit
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNSolanaTransactionParserTests {
    private let ours = "C3sMV8TJunZCdA8QTPpqjgtmm3iKYAWsARjLwqXsDxoB"
    private let other = "meHJjLUcsxmQm2hUyPdVYyq68q7wqK24vGLSdum2yMC"

    private func parser(address: String?) -> WCNSolanaTransactionParser {
        WCNSolanaTransactionParser(accountProvider: StubAccountProvider(address: address))
    }

    private func request(method: String = WCNSolanaTransactionParsed.signMethod, chainId: String = "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", params: Any) throws -> Request {
        try WCNTestFixtures.request(method: method, chainId: chainId, params: AnyCodable(any: params))
    }

    private func raw(_ signers: [String]) throws -> Data {
        try SolanaRawSigningFixtures.rawTransaction(signerKeys: signers.map { try SolanaKit.PublicKey($0).data })
    }

    @Test func spikeVectorWithOurAccountAmongSigners() throws {
        let request = try request(params: ["transaction": SolanaRawSigningFixtures.partiallySigned.base64EncodedString()])
        let result = try parser(address: ours).parse(request: request)
        let parsed = try #require(result as? WCNSolanaTransactionParsed)

        #expect(parsed.rawTransactions == [SolanaRawSigningFixtures.partiallySigned])
        #expect(parsed.requiredSigners == [[other, ours]])
        #expect(parsed.from == ours)
        #expect(parsed.isSignOnly)
        #expect(parsed.makeSendData() == nil)
    }

    @Test func foreignSignersLeaveFromNil() throws {
        let request = try request(params: ["transaction": SolanaRawSigningFixtures.partiallySigned.base64EncodedString()])
        let result = try parser(address: "11111111111111111111111111111111").parse(request: request)
        let parsed = try #require(result)
        #expect(parsed.from == nil)
    }

    @Test func signAllRequiresOurAccountInEveryTransaction() throws {
        let both = try raw([ours]).base64EncodedString()
        let foreign = try raw([other]).base64EncodedString()

        let allOurs = try request(method: WCNSolanaTransactionParsed.signAllMethod, params: ["transactions": [both, both]])
        let mixed = try request(method: WCNSolanaTransactionParsed.signAllMethod, params: ["transactions": [both, foreign]])

        let allOursResult = try parser(address: ours).parse(request: allOurs)
        let mixedResult = try parser(address: ours).parse(request: mixed)
        let allOursParsed = try #require(allOursResult as? WCNSolanaTransactionParsed)
        let mixedParsed = try #require(mixedResult)

        #expect(allOursParsed.rawTransactions.count == 2)
        #expect(allOursParsed.from == ours)
        #expect(mixedParsed.from == nil)
    }

    @Test func signAndSendIsNotSignOnly() throws {
        let request = try request(method: WCNSolanaTransactionParsed.signAndSendMethod, params: ["transaction": try raw([ours]).base64EncodedString(), "sendOptions": ["skipPreflight": true]])
        let result = try parser(address: ours).parse(request: request)
        let parsed = try #require(result)
        #expect(parsed.isSignOnly == false)
    }

    @Test func ignoresOtherNamespaceAndMethods() throws {
        let evm = try request(chainId: "eip155:1", params: ["transaction": "AA=="])
        let message = try request(method: "solana_signMessage", params: ["message": "abc"])
        let evmResult = try parser(address: ours).parse(request: evm)
        let messageResult = try parser(address: ours).parse(request: message)
        #expect(evmResult == nil)
        #expect(messageResult == nil)
    }

    @Test func malformedParamsAreRejected() throws {
        let missing = try request(params: ["foo": "bar"])
        let badBase64 = try request(params: ["transaction": "not base64!!"])
        let emptyBatch = try request(method: WCNSolanaTransactionParsed.signAllMethod, params: ["transactions": [String]()])

        #expect(throws: WCNSolanaTransactionParser.ParsingError.malformedParams) { try parser(address: ours).parse(request: missing) }
        #expect(throws: WCNSolanaTransactionParser.ParsingError.malformedParams) { try parser(address: ours).parse(request: badBase64) }
        #expect(throws: WCNSolanaTransactionParser.ParsingError.malformedParams) { try parser(address: ours).parse(request: emptyBatch) }
    }

    @Test func undecodableTransactionIsRejected() throws {
        let request = try request(params: ["transaction": Data([1, 2, 3]).base64EncodedString()])
        #expect(throws: WCNSolanaTransactionParser.ParsingError.invalidTransaction) { try parser(address: ours).parse(request: request) }
    }
}

private final class StubAccountProvider: ICurrentAddressProvider {
    let address: String?

    init(address: String?) {
        self.address = address
    }
}

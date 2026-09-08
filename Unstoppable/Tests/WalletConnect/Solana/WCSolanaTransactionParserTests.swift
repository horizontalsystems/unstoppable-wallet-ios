import Foundation
import SolanaKit
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCSolanaTransactionParserTests {
    private let ours = "C3sMV8TJunZCdA8QTPpqjgtmm3iKYAWsARjLwqXsDxoB"
    private let other = "meHJjLUcsxmQm2hUyPdVYyq68q7wqK24vGLSdum2yMC"

    private func parser(address: String?) -> WCSolanaTransactionParser {
        WCSolanaTransactionParser(accountProvider: StubAccountProvider(address: address))
    }

    private func request(method: String = WCSolanaTransactionPayload.signMethod, chainId: String = "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", params: Any) throws -> Request {
        try WCTestFixtures.request(method: method, chainId: chainId, params: AnyCodable(any: params))
    }

    private func raw(_ signers: [String]) throws -> Data {
        try SolanaRawSigningFixtures.rawTransaction(signerKeys: signers.map { try SolanaKit.PublicKey($0).data })
    }

    @Test func spikeVectorWithOurAccountAmongSigners() throws {
        let request = try request(params: ["transaction": SolanaRawSigningFixtures.partiallySigned.base64EncodedString()])
        let result = try parser(address: ours).parse(request: request)
        let payload = try #require(result as? WCSolanaTransactionPayload)

        #expect(payload.rawTransactions == [SolanaRawSigningFixtures.partiallySigned])
        #expect(payload.requiredSigners == [[other, ours]])
        #expect(payload.from == ours)
        #expect(payload.isSignOnly)
        #expect(payload.makeSendData() == nil)
    }

    @Test func foreignSignersLeaveFromNil() throws {
        let request = try request(params: ["transaction": SolanaRawSigningFixtures.partiallySigned.base64EncodedString()])
        let result = try parser(address: "11111111111111111111111111111111").parse(request: request)
        let payload = try #require(result)
        #expect(payload.from == nil)
    }

    @Test func tooManyTransactionsAreRejected() throws {
        let request = try request(method: WCSolanaTransactionPayload.signAllMethod, params: ["transactions": Array(repeating: "AA==", count: WCSolanaLimits.maxTransactionsPerRequest + 1)])
        #expect(throws: WCSolanaTransactionParser.ParsingError.malformedParams) {
            try parser(address: ours).parse(request: request)
        }
    }

    @Test func oversizedTransactionIsRejectedBeforeDecode() throws {
        let request = try request(params: ["transaction": String(repeating: "A", count: WCSolanaLimits.maxTransactionBase64Length + 1)])
        #expect(throws: WCSolanaTransactionParser.ParsingError.malformedParams) {
            try parser(address: ours).parse(request: request)
        }
    }

    @Test func signAllRequiresOurAccountInEveryTransaction() throws {
        let both = try raw([ours]).base64EncodedString()
        let foreign = try raw([other]).base64EncodedString()

        let allOurs = try request(method: WCSolanaTransactionPayload.signAllMethod, params: ["transactions": [both, both]])
        let mixed = try request(method: WCSolanaTransactionPayload.signAllMethod, params: ["transactions": [both, foreign]])

        let allOursResult = try parser(address: ours).parse(request: allOurs)
        let mixedResult = try parser(address: ours).parse(request: mixed)
        let allOursPayload = try #require(allOursResult as? WCSolanaTransactionPayload)
        let mixedPayload = try #require(mixedResult)

        #expect(allOursPayload.rawTransactions.count == 2)
        #expect(allOursPayload.from == ours)
        #expect(mixedPayload.from == nil)
    }

    @Test func signAndSendIsNotSignOnly() throws {
        let request = try request(method: WCSolanaTransactionPayload.signAndSendMethod, params: ["transaction": try raw([ours]).base64EncodedString(), "sendOptions": ["skipPreflight": true]])
        let result = try parser(address: ours).parse(request: request)
        let payload = try #require(result)
        #expect(payload.isSignOnly == false)
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
        let emptyBatch = try request(method: WCSolanaTransactionPayload.signAllMethod, params: ["transactions": [String]()])

        #expect(throws: WCSolanaTransactionParser.ParsingError.malformedParams) { try parser(address: ours).parse(request: missing) }
        #expect(throws: WCSolanaTransactionParser.ParsingError.malformedParams) { try parser(address: ours).parse(request: badBase64) }
        #expect(throws: WCSolanaTransactionParser.ParsingError.malformedParams) { try parser(address: ours).parse(request: emptyBatch) }
    }

    @Test func undecodableTransactionIsRejected() throws {
        let request = try request(params: ["transaction": Data([1, 2, 3]).base64EncodedString()])
        #expect(throws: WCSolanaTransactionParser.ParsingError.invalidTransaction) { try parser(address: ours).parse(request: request) }
    }
}

private final class StubAccountProvider: ICurrentAddressProvider {
    let address: String?

    init(address: String?) {
        self.address = address
    }
}

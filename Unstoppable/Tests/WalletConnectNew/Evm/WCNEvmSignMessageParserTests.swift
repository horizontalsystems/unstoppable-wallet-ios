import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNEvmSignMessageParserTests {
    private let parser = WCNEvmSignMessageParser()
    private let address = WCNTestFixtures.address

    static let typedDataJson = """
    {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Permit":[{"name":"owner","type":"address"},{"name":"value","type":"uint256"}]},"primaryType":"Permit","domain":{"name":"USD Coin","chainId":1,"verifyingContract":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"},"message":{"owner":"0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d","value":"1000"}}
    """

    private func parse(method: String, params: Any) throws -> WCNEvmSignMessagePayload {
        let request = try WCNTestFixtures.request(method: method, params: AnyCodable(any: params))
        let result = try parser.parse(request: request)
        return try #require(result as? WCNEvmSignMessagePayload)
    }

    @Test func personalSignWithUtf8Message() throws {
        let payload = try parse(method: "personal_sign", params: ["Sign in to React App", address])

        #expect(payload.kind == .signMessage)
        #expect(payload.from == address)
        #expect(payload.message == Data("Sign in to React App".utf8))
        #expect(payload.readableMessage == "Sign in to React App")
        #expect(payload.typedData == nil)
    }

    @Test func personalSignWithHexMessageAndSwappedParams() throws {
        let payload = try parse(method: "personal_sign", params: [address, "0x48656c6c6f"])
        #expect(payload.from == address)
        #expect(payload.message == Data("Hello".utf8))
    }

    @Test func ethSignTakesAddressFirst() throws {
        let hash = "0x" + String(repeating: "ab", count: 32)
        let payload = try parse(method: "eth_sign", params: [address, hash])
        #expect(payload.from == address)
        #expect(payload.message?.count == 32)
        #expect(payload.readableMessage == hash)
    }

    @Test func typedDataAsStringExtractsDomain() throws {
        let payload = try parse(method: "eth_signTypedData_v4", params: [address, Self.typedDataJson])

        #expect(payload.typedData != nil)
        #expect(payload.typedDataDomain == WCNTypedDataDomain(chainId: 1, verifyingContract: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"))
        #expect(payload.readableMessage.contains("\"owner\""))
    }

    @Test func typedDataAsObjectIsAccepted() throws {
        let object = try JSONSerialization.jsonObject(with: Data(Self.typedDataJson.utf8))
        let payload = try parse(method: "eth_signTypedData", params: [address, object])
        #expect(payload.typedDataDomain?.chainId == 1)
    }

    @Test func missingAddressIsRejected() throws {
        let request = try WCNTestFixtures.request(method: "personal_sign", params: AnyCodable(any: ["hello", "world"]))
        #expect(throws: WCNEvmSignMessageParser.ParsingError.missingAddress) { try parser.parse(request: request) }
    }

    @Test func malformedTypedDataIsRejected() throws {
        let request = try WCNTestFixtures.request(method: "eth_signTypedData_v4", params: AnyCodable(any: [address, "{not json"]))
        #expect(throws: WCNEvmSignMessageParser.ParsingError.malformedParams) { try parser.parse(request: request) }
    }

    @Test func ignoresOtherMethodsAndNamespaces() throws {
        let tx = try WCNTestFixtures.request(method: "eth_sendTransaction", params: AnyCodable(any: [address, "0x"]))
        let solana = try WCNTestFixtures.request(method: "personal_sign", chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", params: AnyCodable(any: ["m", address]))
        let txResult = try parser.parse(request: tx)
        let solanaResult = try parser.parse(request: solana)
        #expect(txResult == nil)
        #expect(solanaResult == nil)
    }
}

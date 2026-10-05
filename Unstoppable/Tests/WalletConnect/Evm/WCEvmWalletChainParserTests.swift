import Testing
import WalletConnectSign
@testable import WalletCore

struct WCEvmWalletChainParserTests {
    private let parser = WCEvmWalletChainParser()

    @Test func parsesHexChainId() throws {
        let request = try WCTestFixtures.request(method: WCEvmWalletChainPayload.switchMethod, params: AnyCodable(any: [["chainId": "0x38"]]))
        let result = try parser.parse(request: request)
        let payload = try #require(result as? WCEvmWalletChainPayload)

        #expect(payload.targetChainId == 56)
        #expect(payload.kind == .direct)
        #expect(payload.from == nil)
    }

    @Test func handlesAddChainWithExtraFields() throws {
        let params: [[String: Any]] = [["chainId": "0xa", "chainName": "Optimism", "rpcUrls": ["https://mainnet.optimism.io"]]]
        let request = try WCTestFixtures.request(method: WCEvmWalletChainPayload.addMethod, params: AnyCodable(any: params))
        let result = try parser.parse(request: request)
        let payload = try #require(result as? WCEvmWalletChainPayload)
        #expect(payload.targetChainId == 10)
    }

    @Test func ignoresOtherMethodsAndNamespaces() throws {
        let other = try WCTestFixtures.request(method: "personal_sign", params: AnyCodable(any: [["chainId": "0x1"]]))
        let solana = try WCTestFixtures.request(method: WCEvmWalletChainPayload.switchMethod, chainId: "solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp", params: AnyCodable(any: [["chainId": "0x1"]]))
        let otherResult = try parser.parse(request: other)
        let solanaResult = try parser.parse(request: solana)
        #expect(otherResult == nil)
        #expect(solanaResult == nil)
    }

    @Test func malformedParamsAreRejected() throws {
        let missing = try WCTestFixtures.request(method: WCEvmWalletChainPayload.switchMethod, params: AnyCodable(any: [[String: String]]()))
        let notHex = try WCTestFixtures.request(method: WCEvmWalletChainPayload.switchMethod, params: AnyCodable(any: [["chainId": "mainnet"]]))

        #expect(throws: WCEvmWalletChainParser.ParsingError.malformedParams) { try parser.parse(request: missing) }
        #expect(throws: WCEvmWalletChainParser.ParsingError.malformedParams) { try parser.parse(request: notHex) }
    }
}

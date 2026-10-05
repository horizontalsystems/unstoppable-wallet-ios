import EvmKit
import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCEvmSignMessageHandlerTests {
    private let client = WCSpySignClient()
    private let parser = WCEvmSignMessageParser()
    private static let privateKey = Data(repeating: 0x11, count: 32)
    private static let chain = Chain(id: 1, coinType: 60, syncInterval: 15, isEIP1559Supported: true)

    private var signer: EvmKit.Signer { EvmKit.Signer.instance(privateKey: Self.privateKey, chain: Self.chain) }

    private func handler(provider: IWCEvmSignerProvider) -> WCEvmSignMessageHandler {
        WCEvmSignMessageHandler(signerProvider: provider, responder: WCResponder(signClient: client))
    }

    private func request(method: String, params: [Any]) throws -> WCRequest {
        let raw = try WCTestFixtures.request(method: method, params: AnyCodable(any: params))
        let parsed = try parser.parse(request: raw)
        let payload = try #require(parsed)
        return WCRequest(payload: payload, verdict: .pass, dAppName: "dApp")
    }

    private func signatureHex(at index: Int = 0) throws -> String {
        let call = try #require(client.calls.count > index ? client.calls[index] : nil)
        guard case let .response(value) = call.response else {
            Issue.record("expected response")
            return ""
        }
        return try value.get(String.self)
    }

    @Test func personalSignProducesSignature() async throws {
        let request = try request(method: "personal_sign", params: ["Sign in", EvmKit.Signer.address(privateKey: Self.privateKey).eip55])

        try await handler(provider: StubSignerProvider(signer: signer)).sign(request: request)

        let hex = try signatureHex()
        #expect(hex.hasPrefix("0x"))
        #expect(hex.count == 132)
    }

    @Test func typedDataUsesEip712Signing() async throws {
        let address = EvmKit.Signer.address(privateKey: Self.privateKey).eip55
        let typed = try request(method: "eth_signTypedData_v4", params: [address, WCEvmSignMessageParserTests.typedDataJson])
        let personal = try request(method: "personal_sign", params: [WCEvmSignMessageParserTests.typedDataJson, address])

        try await handler(provider: StubSignerProvider(signer: signer)).sign(request: typed)
        try await handler(provider: StubSignerProvider(signer: signer)).sign(request: personal)
        let typedHex = try signatureHex(at: 0)
        let personalHex = try signatureHex(at: 1)

        #expect(typedHex.count == 132)
        #expect(typedHex != personalHex)
    }

    @Test func missingSignerFails() async throws {
        let request = try request(method: "personal_sign", params: ["Sign in", EvmKit.Signer.address(privateKey: Self.privateKey).eip55])
        await #expect(throws: WCEvmSignMessageHandler.SignError.self) {
            try await handler(provider: StubSignerProvider(signer: nil)).sign(request: request)
        }
        #expect(client.calls.isEmpty)
    }

    @Test func expiredRequestIsRejectedBeforeLookingUpSigner() async throws {
        var raw = try WCTestFixtures.request(method: "personal_sign", params: AnyCodable(any: ["Sign in", EvmKit.Signer.address(privateKey: Self.privateKey).eip55]))
        raw.expiryTimestamp = 0
        let parsed = try parser.parse(request: raw)
        let payload = try #require(parsed)
        let request = WCRequest(payload: payload, verdict: .pass, dAppName: "dApp")

        await #expect(throws: WCRequest.RequestError.expired) {
            try await handler(provider: StubSignerProvider(signer: nil)).sign(request: request)
        }
        #expect(client.calls.isEmpty)
    }

    @Test func handlesOnlySignMessagePayloads() throws {
        let sign = try request(method: "personal_sign", params: ["Sign in", EvmKit.Signer.address(privateKey: Self.privateKey).eip55]).payload
        let other = try WCStubRequestPayload.make()
        #expect(handler(provider: StubSignerProvider(signer: nil)).handles(sign))
        #expect(handler(provider: StubSignerProvider(signer: nil)).handles(other) == false)
    }
}

private final class StubSignerProvider: IWCEvmSignerProvider {
    private let stubSigner: EvmKit.Signer?

    init(signer: EvmKit.Signer?) {
        stubSigner = signer
    }

    func signer(chainId _: Int) -> EvmKit.Signer? { stubSigner }
}

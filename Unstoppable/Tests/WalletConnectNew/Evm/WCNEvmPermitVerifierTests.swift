import Foundation
import Testing
import WalletConnectSign
@testable import WalletCore

struct WCNEvmPermitVerifierTests {
    private let verifier = WCNEvmPermitVerifier()
    private let parser = WCNEvmSignMessageParser()
    private let maxUint256 = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

    private func permit(value: String) -> String {
        """
        {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Permit":[{"name":"owner","type":"address"},{"name":"spender","type":"address"},{"name":"value","type":"uint256"},{"name":"nonce","type":"uint256"},{"name":"deadline","type":"uint256"}]},"primaryType":"Permit","domain":{"name":"USD Coin","chainId":1,"verifyingContract":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"},"message":{"owner":"0x3f4E9c3Ac73a4cff7540293c24a3D055E03fd78d","spender":"0x1111111254EEB25477B68fb85Ed929f73A960582","value":"\(value)","nonce":"1","deadline":"1999999999"}}
        """
    }

    private func permit2(amount: String, contract: String = WCNEvmPermitVerifier.permit2Contract) -> String {
        """
        {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"PermitSingle":[{"name":"details","type":"PermitDetails"},{"name":"spender","type":"address"},{"name":"sigDeadline","type":"uint256"}],"PermitDetails":[{"name":"token","type":"address"},{"name":"amount","type":"uint160"},{"name":"expiration","type":"uint48"},{"name":"nonce","type":"uint48"}]},"primaryType":"PermitSingle","domain":{"name":"Permit2","chainId":1,"verifyingContract":"\(contract)"},"message":{"details":{"token":"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","amount":"\(amount)","expiration":"1999999999","nonce":"0"},"spender":"0x1111111254EEB25477B68fb85Ed929f73A960582","sigDeadline":"1999999999"}}
        """
    }

    private func context(json: String) throws -> WCNVerificationContext {
        let request = try WCNTestFixtures.request(method: "eth_signTypedData_v4", params: AnyCodable(any: [WCNTestFixtures.address, json]))
        let parsed = try parser.parse(request: request)
        let payload = try #require(parsed)
        return try WCNTestFixtures.context(payload: payload)
    }

    @Test func unlimitedPermitIsCaution() throws {
        let context = try context(json: permit(value: maxUint256))
        #expect(verifier.handles(context))
        #expect(verifier.verify(context) == .caution(reason: .permitUnlimitedAllowance(spender: "0x1111111254EEB25477B68fb85Ed929f73A960582")))
    }

    @Test func boundedPermitPasses() throws {
        let context = try context(json: permit(value: "1000000"))
        #expect(verifier.verify(context) == .pass)
    }

    @Test func unlimitedPermit2IsCaution() throws {
        let context = try context(json: permit2(amount: "1461501637330902918203684832716283019655932542975"))
        #expect(verifier.verify(context) == .caution(reason: .permitUnlimitedAllowance(spender: "0x1111111254EEB25477B68fb85Ed929f73A960582")))
    }

    @Test func permit2OnForeignContractIsIgnored() throws {
        let context = try context(json: permit2(amount: "1461501637330902918203684832716283019655932542975", contract: "0x000000000000000000000000000000000000dEaD"))
        #expect(verifier.verify(context) == .pass)
    }

    @Test func ignoresPlainMessages() throws {
        let context = try WCNTestFixtures.context(payload: WCNStubRequestPayload.make(method: "personal_sign", kind: .signMessage))
        #expect(verifier.handles(context) == false)
    }
}

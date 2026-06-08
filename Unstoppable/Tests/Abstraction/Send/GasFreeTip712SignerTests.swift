import Foundation
import Testing
@testable import Unstoppable
@testable import WalletCore

struct GasFreeTip712SignerTests {
    private let privateKey = Data(repeating: 0x42, count: 32)
    private let messageHash = Data(repeating: 0xCC, count: 32)

    @Test func produces65ByteSignature() throws {
        let signature = try GasFreeTip712Signer.sign(messageHash: messageHash, privateKey: privateKey)

        #expect(signature.count == 65)
    }

    @Test func recoveryIdIsNormalisedToEthereumConvention() throws {
        let signature = try GasFreeTip712Signer.sign(messageHash: messageHash, privateKey: privateKey)
        let v = try #require(signature.last)

        #expect(v == 27 || v == 28)
    }

    @Test func signatureIsDeterministicForSameInputs() throws {
        let first = try GasFreeTip712Signer.sign(messageHash: messageHash, privateKey: privateKey)
        let second = try GasFreeTip712Signer.sign(messageHash: messageHash, privateKey: privateKey)

        #expect(first == second)
    }

    @Test func differentMessageHashProducesDifferentSignature() throws {
        let hashA = Data(repeating: 0xAA, count: 32)
        let hashB = Data(repeating: 0xBB, count: 32)

        let sigA = try GasFreeTip712Signer.sign(messageHash: hashA, privateKey: privateKey)
        let sigB = try GasFreeTip712Signer.sign(messageHash: hashB, privateKey: privateKey)

        #expect(sigA != sigB)
    }
}

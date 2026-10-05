import CryptoKit
import Foundation
import SolanaKit
import Testing

struct SolanaKitRawSigningTests {
    @Test func derivedAddressMatchesVector() throws {
        let signer = try Signer.instance(seed: SolanaRawSigningFixtures.seed)
        #expect(signer.address.base58 == SolanaRawSigningFixtures.ours)
    }

    @Test func requiredSignersInMessageOrder() throws {
        let signers = try Kit.requiredSigners(rawTransaction: SolanaRawSigningFixtures.partiallySigned)
        #expect(signers == [SolanaRawSigningFixtures.other, SolanaRawSigningFixtures.ours])
    }

    // CryptoKit Ed25519 signatures are randomized, so only the bytes outside our slot are compared
    // byte-for-byte; our signature is verified cryptographically against the message.
    @Test func requiredSignersOfBareMessageMatchTransaction() throws {
        let message = SolanaRawSigningFixtures.partiallySigned.dropFirst(129)
        let signers = try Kit.requiredSigners(message: message)
        #expect(signers == [SolanaRawSigningFixtures.other, SolanaRawSigningFixtures.ours])
    }

    @Test func signsIntoOwnSlotPreservingOtherSignature() throws {
        let signer = try Signer.instance(seed: SolanaRawSigningFixtures.seed)
        let result = try Kit.sign(rawTransaction: SolanaRawSigningFixtures.partiallySigned, signer: signer)

        try expectSignedLikeVector(result)
    }

    @Test func signingIsIdempotentOnSignedTransaction() throws {
        let signer = try Signer.instance(seed: SolanaRawSigningFixtures.seed)
        let result = try Kit.sign(rawTransaction: SolanaRawSigningFixtures.fullySigned, signer: signer)

        try expectSignedLikeVector(result)
    }

    private func expectSignedLikeVector(_ result: (transaction: Data, signature: Data)) throws {
        let expected = SolanaRawSigningFixtures.fullySigned
        #expect(result.transaction.count == expected.count)
        #expect(result.transaction[0 ..< 65] == expected[0 ..< 65])
        #expect(result.transaction[129...] == expected[129...])
        #expect(result.transaction[65 ..< 129] == result.signature)

        let publicKey = try Curve25519.Signing.PublicKey(rawRepresentation: SolanaRawSigningFixtures.oursPublicKey)
        #expect(publicKey.isValidSignature(result.signature, for: expected[129...]))
    }

    @Test func foreignSignerIsRejected() throws {
        let foreign = try Signer.instance(seed: SolanaRawSigningFixtures.foreignSeed)
        #expect(throws: SignRawTransactionError.self) {
            try Kit.sign(rawTransaction: SolanaRawSigningFixtures.partiallySigned, signer: foreign)
        }
    }

    @Test func malformedTransactionThrows() throws {
        let signer = try Signer.instance(seed: SolanaRawSigningFixtures.seed)
        #expect(throws: (any Error).self) {
            try Kit.sign(rawTransaction: SolanaRawSigningFixtures.partiallySigned.prefix(40), signer: signer)
        }
    }
}

import BigInt
import Foundation

// Canonical test vectors captured from `gasfreeio/gasfree-sdk-swift`
// Example/Tests/Tests.swift (Phase 0).
//
// Source:
//   https://github.com/gasfreeio/gasfree-sdk-swift/blob/main/Example/Tests/Tests.swift
//
// Consumers (added in later phases):
//   - GasFreeAddressResolverTests        (Phase 1.8) → AddressDerivation
//   - PermitTransferHashTests            (Phase 4.3) → PermitTransferHash
//
// Each vector matches a canonical XCTest in the upstream SDK. Adding
// more vectors requires running the SDK locally with new inputs and
// recording (input, output) pairs here.
enum GasFreeFixtures {
    enum AddressDerivation {
        struct Vector {
            let userAddress: String
            let expectedGasFreeAddress: String
        }

        // Source: testGenerateGasFreeAddress
        static let mainnetExample = Vector(
            userAddress: "TLFXfejEMgivFDR2x8qBpukMXd56spmFhz",
            expectedGasFreeAddress: "TYKTmMyTeAFrfdRTpYHjnAtFEJtMMotJJe"
        )
    }

    enum PermitTransferHash {
        struct Vector {
            let chainId: BigUInt
            let verifyingContract: String
            let token: String
            let serviceProvider: String
            let user: String
            let receiver: String
            let value: BigUInt
            let maxFee: BigUInt
            let deadline: Int64
            let version: Int64
            let nonce: Int64
            // Hex without "0x" prefix; matches Crypto.sha3 output bytes.
            let expectedHashHex: String
        }

        // Source: testGasFreeMessageParam (and testGasFree712StructHash —
        // identical inputs through two SDK entry points, same hash output).
        static let mainnetExample = Vector(
            chainId: BigUInt(728_126_428), // 0x2b6653dc
            verifyingContract: "TFFAMQLZybALaLb4uxHA9RBE7pxhUAjF3U",
            token: "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t", // TRC-20 USDT
            serviceProvider: "TLntW9Z59LYY5KEi9cmwk3PKjQga828ird",
            user: "TFDP1vFeSYPT6FUznL7zUjhg5X7p2AA8vw",
            receiver: "TSPrmJetAMo6S6RxMd4tswzeRCFVegBNig",
            value: BigUInt(20_000_000),
            maxFee: BigUInt(20_000_000),
            deadline: 1_740_641_152,
            version: 1,
            nonce: 1,
            expectedHashHex: "4e0e1444d20768c286b9de66064e4e7311b5160871c8c0292ffeac9a16265622"
        )
    }
}

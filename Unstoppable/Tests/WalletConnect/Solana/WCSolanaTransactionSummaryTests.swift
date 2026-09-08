import Foundation
import SolanaKit
import Testing
@testable import WalletCore

struct WCSolanaTransactionSummaryTests {
    private let ours = SolanaRawSigningFixtures.oursPublicKey
    private let other = SolanaRawSigningFixtures.other

    // 1000-lamport system transfer from `other` to `ours`
    @Test func decodesSystemTransfer() {
        let summary = WCSolanaTransactionSummary(rawTransaction: SolanaRawSigningFixtures.partiallySigned)

        #expect(summary.method == .transfer)
        #expect(summary.transfers.count == 1)
        #expect(summary.transfers[0].isSol)
        #expect(summary.transfers[0].amount == 1000)
        #expect(summary.transfers[0].destination == SolanaRawSigningFixtures.ours)
        #expect(summary.opaque == false)
    }

    @Test func decodesSplTransferChecked() throws {
        let destination = try PublicKey(other).data
        var data = Data([12])
        data.append(contentsOf: [0xE8, 0x03, 0, 0, 0, 0, 0, 0]) // 1000, little-endian
        data.append(6)
        // accounts [source, mint, destination, owner]: mint reuses the program slot, destination is key 1
        let raw = SolanaRawSigningFixtures.rawTransaction(signerKeys: [ours, destination], programKey: PublicKey.tokenProgramId.data, accountIndices: [0, 2, 1, 0], instructionData: data)
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)

        #expect(summary.method == .transfer)
        #expect(summary.transfers[0].isSol == false)
        #expect(summary.transfers[0].amount == 1000)
        #expect(summary.transfers[0].decimals == 6)
        #expect(summary.transfers[0].destination == other)
    }

    @Test func swapProgramMarksSwapWithoutAmounts() throws {
        let raw = SolanaRawSigningFixtures.rawTransaction(signerKeys: [ours], programKey: try PublicKey(KnownPrograms.jupiterV6).data)
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)

        #expect(summary.method == .swap)
        #expect(summary.transfers.isEmpty)
        #expect(summary.opaque == false)
    }

    @Test func unknownProgramIsOpaque() {
        let summary = WCSolanaTransactionSummary(rawTransaction: SolanaRawSigningFixtures.rawTransaction(signerKeys: [ours], programKey: Data(repeating: 0x22, count: 32)))

        #expect(summary.method == nil)
        #expect(summary.opaque)
    }

    @Test func malformedBytesAreOpaque() {
        let summary = WCSolanaTransactionSummary(rawTransaction: Data([1, 2, 3]))
        #expect(summary.opaque)
    }
}

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
        #expect(summary.transfers[0].destination == .address(SolanaRawSigningFixtures.ours))
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
        #expect(summary.transfers[0].destination == .address(other))
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

    @Test(arguments: [false, true]) func lookupRecipientIsExplicit(readonly: Bool) throws {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data], instructions: [.init(program: 1, accounts: [0, 2], data: SolanaRawSigningFixtures.systemTransferData)], version: 0x80, writableLookupIndices: readonly ? [] : [4], readonlyLookupIndices: readonly ? [4] : [])
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        let transfer = try #require(summary.transfers.first)
        #expect(transfer.destination == .lookupTable)
        #expect(summary.warnings == [.hiddenRecipient])
    }

    @Test(arguments: [UInt8(2), 255]) func invalidAccountIndexIsUnreadable(index: UInt8) {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data], instructions: [.init(program: 1, accounts: [0, index], data: SolanaRawSigningFixtures.systemTransferData)])
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        #expect(summary.transfers.isEmpty)
        #expect(summary.warnings == [.unreadable])
    }

    @Test func invalidUnusedIndexIsNotIgnoredByKnownProgram() throws {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, try PublicKey(KnownPrograms.jupiterV6).data], instructions: [.init(program: 1, accounts: [255], data: Data())])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unreadable])
    }

    @Test func invalidProgramIndexIsUnreadable() {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours], instructions: [.init(program: 255, accounts: [0], data: Data())])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unreadable])
    }

    @Test func missingTransferAccountIsUnreadable() {
        let raw = SolanaRawSigningFixtures.rawTransaction(signerKeys: [ours], accountIndices: [0], instructionData: SolanaRawSigningFixtures.systemTransferData)
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unreadable])
    }

    @Test(arguments: [UInt8(4), 6, 8]) func tokenActionBesideTransferWarns(discriminator: UInt8) {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data, PublicKey.tokenProgramId.data], instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [0], data: Data([discriminator]))])
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        #expect(summary.transfers.count == 1)
        #expect(summary.warnings == [.unknownInstructions])
    }

    @Test func unknownProgramBesideTransferWarns() {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data, Data(repeating: 0x22, count: 32)], instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [0], data: Data())])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unknownInstructions])
    }

    @Test func hiddenRecipientDoesNotEraseUnknownInstructionWarning() {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data, Data(repeating: 0x22, count: 32)], instructions: [.init(program: 1, accounts: [0, 3], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [0], data: Data())], version: 0x80, readonlyLookupIndices: [7])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.hiddenRecipient, .unknownInstructions])
    }

    @Test func createAccountWithSeedIsNotSilentlyIgnored() {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data], instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 1, accounts: [0, 0], data: Data([3, 0, 0, 0]))])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unknownInstructions])
    }

    @Test(arguments: [UInt8(0), 1, 2]) func associatedTokenExemptionExcludesRecoverNested(discriminator: UInt8) throws {
        let ata = try PublicKey("ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL").data
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data, ata], instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [0], data: Data([discriminator]))])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == (discriminator == 2 ? [.unknownInstructions] : []))
    }

    @Test(arguments: [UInt8(1), 17, 18]) func tokenInitializationAndSyncRemainExempt(discriminator: UInt8) {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data, PublicKey.tokenProgramId.data], instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [0], data: Data([discriminator]))])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings.isEmpty)
    }

    @Test func computeBudgetAndMemoDoNotAddUnknownWarnings() throws {
        let programs = try ["ComputeBudget111111111111111111111111111111", "MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr", "Memo1UhkJRfHyvLMcVucJwxXeuD728EqVDDwQDxFMNo"].map { try PublicKey($0).data }
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data] + programs, instructions: [.init(program: 1, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 2, accounts: [], data: Data([2, 1, 0, 0, 0])), .init(program: 3, accounts: [], data: Data("memo".utf8)), .init(program: 4, accounts: [], data: Data("memo".utf8))])
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings.isEmpty)
    }

    @Test func createAccountShowsFundingTransfer() throws {
        let destination = try PublicKey(other).data
        var data = Data([0, 0, 0, 0, 0xE8, 3, 0, 0, 0, 0, 0, 0])
        data.append(Data(repeating: 0, count: 40))
        let raw = SolanaRawSigningFixtures.rawTransaction(signerKeys: [ours, destination], accountIndices: [0, 1], instructionData: data)
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        let transfer = try #require(summary.transfers.first)
        #expect(transfer.amount == 1000)
        #expect(transfer.destination == .address(other))
        #expect(summary.warnings.isEmpty)
    }

    @Test(arguments: [UInt8(0), 1, 4]) func closeAccountOnlyAcceptsKnownOwnerDestination(destination: UInt8) throws {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, try PublicKey(other).data, PublicKey.systemProgramId.data, PublicKey.tokenProgramId.data], instructions: [.init(program: 2, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData), .init(program: 3, accounts: [0, destination, 0], data: Data([9]))], version: 0x80, writableLookupIndices: [1])
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        #expect(summary.warnings == (destination == 0 ? [] : [.unknownInstructions]))
    }

    @Test func sourceIsAuthorityNotTokenAccountOrFeePayer() throws {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, try PublicKey(other).data, PublicKey.tokenProgramId.data], instructions: [.init(program: 2, accounts: [0, 0, 1], data: Data([3, 1, 0, 0, 0, 0, 0, 0, 0]))])
        let summary = WCSolanaTransactionSummary(rawTransaction: raw)
        #expect(summary.feePayer == SolanaRawSigningFixtures.ours)
        #expect(summary.transfers.first?.source == .address(other))
    }

    @Test(arguments: [UInt8(0x81), 0xFF]) func unsupportedMessageVersionIsRejected(version: UInt8) {
        let raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours], instructions: [], version: version)
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unreadable])
        #expect(throws: SolanaSerializer.SerializerError.self) { try SolanaSerializer.deserialize(transactionData: raw) }
    }

    @Test func missingV0LookupCountIsRejected() {
        var raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours], instructions: [], version: 0x80)
        raw.removeLast()
        #expect(throws: SolanaSerializer.SerializerError.self) { try SolanaSerializer.deserialize(transactionData: raw) }
    }

    @Test func truncatedV0LookupSectionIsRejected() {
        var raw = SolanaRawSigningFixtures.summaryTransaction(keys: [ours, PublicKey.systemProgramId.data], instructions: [.init(program: 1, accounts: [0, 2], data: SolanaRawSigningFixtures.systemTransferData)], version: 0x80, readonlyLookupIndices: [2])
        raw.removeLast()
        #expect(WCSolanaTransactionSummary(rawTransaction: raw).warnings == [.unreadable])
        #expect(throws: SolanaSerializer.SerializerError.self) { try SolanaSerializer.deserialize(transactionData: raw) }
    }

    @Test func fusionIsRecognizedOnlyWhenInvoked() throws {
        let keys = [ours, try PublicKey(KnownPrograms.oneInchFusion).data, PublicKey.systemProgramId.data]
        let swap = SolanaRawSigningFixtures.summaryTransaction(keys: keys, instructions: [.init(program: 1, accounts: [0], data: Data())])
        let transfer = SolanaRawSigningFixtures.summaryTransaction(keys: keys, instructions: [.init(program: 2, accounts: [0, 0], data: SolanaRawSigningFixtures.systemTransferData)])
        #expect(KnownPrograms.all.contains(KnownPrograms.oneInchFusion))
        #expect(WCSolanaTransactionSummary(rawTransaction: swap).method == .swap)
        #expect(WCSolanaTransactionSummary(rawTransaction: transfer).method == .transfer)
    }

    @Test(arguments: [false, true]) func fusionLabelHasPriorityRegardlessOfInstructionOrder(reversed: Bool) {
        let programs = reversed ? [KnownPrograms.jupiterV6, KnownPrograms.oneInchFusion] : [KnownPrograms.oneInchFusion, KnownPrograms.jupiterV6]
        #expect(SolanaTransactionConverter.swapExchangeName(programIds: programs.joined(separator: " ")) == "1inch")
        #expect(SolanaTransactionConverter.swapExchangeName(programIds: PublicKey.systemProgramId.base58) == nil)
        #expect(SolanaTransactionConverter.swapExchangeName(programIds: nil) == nil)
    }
}

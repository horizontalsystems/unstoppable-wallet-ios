import Foundation
import GRDB
import Testing
@testable import WalletCore

struct ScannedTransactionStorageTests {
    @Test func markingContactClearsMatchingSpamAcrossNetworksAndKeepsOtherAddresses() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("contact-spam-\(UUID().uuidString).sqlite").path
        let storage = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))
        try storage.save(scannedTransactions: [
            ScannedTransaction(transactionHash: Data([1]), blockchainTypeUid: "ethereum", isSpam: true, spamAddress: "0xAbC"),
            ScannedTransaction(transactionHash: Data([2]), blockchainTypeUid: "ethereum", isSpam: true, spamAddress: "0xabc"),
            ScannedTransaction(transactionHash: Data([3]), blockchainTypeUid: "other-network", isSpam: true, spamAddress: "0xabc"),
            ScannedTransaction(transactionHash: Data([4]), blockchainTypeUid: "ethereum", isSpam: true, spamAddress: "0xdef"),
        ])

        try storage.markNotSpam(addresses: ["0xABC"])

        for hash: UInt8 in [1, 2, 3] {
            let scanned = try storage.findScanned(transactionHash: Data([hash]))
            let row = try #require(scanned)
            #expect(row.isSpam == false)
            #expect(row.spamAddress == nil)
        }
        let otherAddress = try storage.findScanned(transactionHash: Data([4]))
        let clearedAddress = try storage.findScanned(address: "0xabc")
        #expect(otherAddress?.isSpam == true)
        #expect(clearedAddress == nil)
    }

    @Test func clearedVerdictPersistsWhenContactIsAbsentAfterReload() throws {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("contact-spam-\(UUID().uuidString).sqlite").path
        let storage = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))
        let address = "0xabc"
        try storage.save(scannedTransaction: ScannedTransaction(transactionHash: Data([1]), blockchainTypeUid: "ethereum", isSpam: true, spamAddress: address))

        try storage.markNotSpam(addresses: [address])
        try storage.markNotSpam(addresses: [address])

        let reloaded = try ScannedTransactionStorage(dbPool: DatabasePool(path: path))
        try reloaded.markNotSpam(addresses: [])

        let scanned = try reloaded.findScanned(transactionHash: Data([1]))
        let row = try #require(scanned)
        #expect(row.isSpam == false)
        let clearedAddress = try reloaded.findScanned(address: address)
        #expect(clearedAddress == nil)
    }
}

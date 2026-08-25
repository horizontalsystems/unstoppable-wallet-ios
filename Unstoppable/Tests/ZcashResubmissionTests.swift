import Foundation
import GRDB
import Testing
@testable import WalletCore
import ZcashLightClientKit

struct ZcashResubmissionTests {
    private func makeStorage() throws -> ZcashAdapterStorage {
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("zcash-resubmission-tests-\(UUID().uuidString).sqlite").path
        let dbPool = try DatabasePool(path: path)
        return try ZcashAdapterStorage(dbPool: dbPool)
    }

    private func makeStore(storage: ZcashAdapterStorage, uniqueId: String = "wallet-1") -> ZcashTerminalResubmissionStore {
        ZcashTerminalResubmissionStore(uniqueId: uniqueId, network: "main", storage: storage)
    }

    // MARK: - Candidate predicate

    @Test func candidateRejectsZeroHeight() {
        let eligible = ZcashSendService.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 100, latestHeight: 0)
        #expect(eligible == false)
    }

    @Test func candidateRejectsExpired() {
        let eligible = ZcashSendService.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 100, latestHeight: 100)
        #expect(eligible == false)
    }

    @Test func candidateRejectsReceived() {
        let eligible = ZcashSendService.isResubmissionCandidate(isSentTransaction: false, minedHeight: nil, hasRaw: true, expiryHeight: 100, latestHeight: 50)
        #expect(eligible == false)
    }

    @Test func candidateRejectsMined() {
        let eligible = ZcashSendService.isResubmissionCandidate(isSentTransaction: true, minedHeight: 90, hasRaw: true, expiryHeight: 100, latestHeight: 50)
        #expect(eligible == false)
    }

    @Test func candidateRejectsMissingRaw() {
        let eligible = ZcashSendService.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: false, expiryHeight: 100, latestHeight: 50)
        #expect(eligible == false)
    }

    @Test func candidateAcceptsPendingUnexpired() {
        let eligible = ZcashSendService.isResubmissionCandidate(isSentTransaction: true, minedHeight: nil, hasRaw: true, expiryHeight: 100, latestHeight: 50)
        #expect(eligible == true)
    }

    // MARK: - Terminal error classifier

    @Test func classifierMarksCode25Terminal() {
        let terminal = ZcashSendService.isTerminalSubmitError(TransactionEncoderError.submitError(code: -25, message: "tx unpaid action limit exceeded"))
        #expect(terminal == true)
    }

    @Test func classifierKeepsOtherNodeErrorsRetryable() {
        let terminal = ZcashSendService.isTerminalSubmitError(TransactionEncoderError.submitError(code: -26, message: "rejected"))
        #expect(terminal == false)
    }

    @Test func classifierKeepsTransportErrorsRetryable() {
        let terminal = ZcashSendService.isTerminalSubmitError(URLError(.timedOut))
        #expect(terminal == false)
    }

    // MARK: - Terminal store

    @Test func markedTransactionIsSuppressed() throws {
        let store = try makeStore(storage: makeStorage())
        #expect(store.isMarked(txId: "aa") == false)

        store.markNodeRejected(txId: "aa", expiryHeight: 100)
        #expect(store.isMarked(txId: "aa") == true)
        #expect(store.isMarked(txId: "bb") == false)
    }

    @Test func markerSurvivesReload() throws {
        let storage = try makeStorage()
        makeStore(storage: storage).markNodeRejected(txId: "aa", expiryHeight: 100)

        let reloaded = makeStore(storage: storage)
        #expect(reloaded.isMarked(txId: "aa") == true)
    }

    @Test func markerIsScopedToAccount() throws {
        let storage = try makeStorage()
        makeStore(storage: storage, uniqueId: "wallet-1").markNodeRejected(txId: "aa", expiryHeight: 100)

        let otherWallet = makeStore(storage: storage, uniqueId: "wallet-2")
        #expect(otherWallet.isMarked(txId: "aa") == false)
    }

    @Test func pruneRemovesGoneTransaction() throws {
        let storage = try makeStorage()
        let store = makeStore(storage: storage)
        store.markNodeRejected(txId: "aa", expiryHeight: 100)

        store.prune(activeUnminedTxIds: [], latestHeight: 50)
        #expect(store.isMarked(txId: "aa") == false)

        let reloaded = makeStore(storage: storage)
        #expect(reloaded.isMarked(txId: "aa") == false)
    }

    @Test func pruneRemovesExpiredTransaction() throws {
        let store = try makeStore(storage: makeStorage())
        store.markNodeRejected(txId: "aa", expiryHeight: 100)

        store.prune(activeUnminedTxIds: ["aa"], latestHeight: 100)
        #expect(store.isMarked(txId: "aa") == false)
    }

    @Test func pruneKeepsActiveUnexpiredMarker() throws {
        let store = try makeStore(storage: makeStorage())
        store.markNodeRejected(txId: "aa", expiryHeight: 100)

        store.prune(activeUnminedTxIds: ["aa"], latestHeight: 99)
        #expect(store.isMarked(txId: "aa") == true)
    }

    @Test func pruneAtZeroHeightKeepsMarker() throws {
        let store = try makeStore(storage: makeStorage())
        store.markNodeRejected(txId: "aa", expiryHeight: 100)

        store.prune(activeUnminedTxIds: ["aa"], latestHeight: 0)
        #expect(store.isMarked(txId: "aa") == true)
    }
}

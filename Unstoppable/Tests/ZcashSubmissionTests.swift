import Foundation
import Testing
@testable import WalletCore
import ZcashLightClientKit

struct ZcashSubmissionTests {
    private let txA = Data([1, 2, 3])
    private let txB = Data([4, 5, 6])
    private let endpoint = LightWalletEndpoint(address: "a", port: 443)

    @Test func allAcceptedIsFullSuccess() {
        let result = ZcashSendService.submitOutcomes([(txA, .accepted(by: endpoint)), (txB, .accepted(by: endpoint))])
        #expect(result.successCount == 2)
        #expect(result.submitFailure == nil)
    }

    @Test func rejectionIsSubmitFailureButLaterTxStillReported() {
        let result = ZcashSendService.submitOutcomes([(txA, .rejected(code: -25, message: "dup")), (txB, .accepted(by: endpoint))])
        #expect(result.successCount == 1)
        #expect(result.submitFailure != nil)
        #expect(result.txIds.count == 2)
    }

    @Test func unreachableIsResubmitableGrpcFailure() {
        let result = ZcashSendService.submitOutcomes([(txA, .unreachable)])
        #expect(result.successCount == 0)
        #expect(result.submitFailure == nil)
        #expect(result.resubmitable == true)
    }

    @Test func everyCreatedTransactionIsSubmittedEvenAfterRejection() async {
        let broadcaster = MockZcashBroadcaster(outcomes: [.rejected(code: -25, message: "dup"), .accepted(by: endpoint)])
        let created = [CreatedTransaction(txId: txA, raw: Data(), expiryHeight: nil), CreatedTransaction(txId: txB, raw: Data(), expiryHeight: nil)]
        _ = await ZcashSendService.submit(created: created, via: broadcaster, endpoint: endpoint)
        #expect(broadcaster.submitted == [txA, txB])
    }
}

final class MockZcashBroadcaster: Broadcaster {
    private var outcomes: [TransactionSubmissionOutcome]
    private(set) var submitted: [Data] = []
    private(set) var released: [Data] = []

    init(outcomes: [TransactionSubmissionOutcome]) {
        self.outcomes = outcomes
    }

    func createProposedTransactions(proposal _: Proposal, spendingKey _: UnifiedSpendingKey) async throws -> [CreatedTransaction] {
        []
    }

    func createTransactionFromPCZT(pcztWithProofs _: Pczt, pcztWithSigs _: Pczt) async throws -> [CreatedTransaction] {
        []
    }

    func submit(transaction: CreatedTransaction, to _: [LightWalletEndpoint], timing _: SubmissionTiming) async -> TransactionSubmissionOutcome {
        submitted.append(transaction.txId)
        return outcomes.isEmpty ? .unreachable : outcomes.removeFirst()
    }

    func submit(transactions: [CreatedTransaction], to endpoints: [LightWalletEndpoint], timing: SubmissionTiming) async -> [TransactionSubmissionReport] {
        var reports: [TransactionSubmissionReport] = []
        for transaction in transactions {
            await reports.append(.init(txId: transaction.txId, outcome: submit(transaction: transaction, to: endpoints, timing: timing)))
        }
        return reports
    }

    func releaseForResubmission(transactions: [CreatedTransaction], to _: [LightWalletEndpoint]) async {
        released.append(contentsOf: transactions.map(\.txId))
    }
}

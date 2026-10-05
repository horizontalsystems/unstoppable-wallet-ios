import Foundation
import ZcashLightClientKit

protocol IZcashMigrationEngine: AnyObject {
    // Propose a send-max sweep of the account's spendable Orchard funds to its own Unified Address;
    // the SDK states both the net amount and the fee. Used by the confirmation screen.
    func quote() async throws -> (amount: Zatoshi, fee: Zatoshi)
    // Re-propose fresh and execute the sweep, returning the first broadcast txid (display hex),
    // or nil if no transaction landed.
    func migrate() async throws -> String?
}

final class ZcashMigrationEngine: IZcashMigrationEngine {
    private let synchronizer: Synchronizer
    private let accountUUID: AccountUUID
    private let spendingKey: UnifiedSpendingKey
    private weak var endpointService: ZcashEndpointService?

    init(synchronizer: Synchronizer, accountUUID: AccountUUID, spendingKey: UnifiedSpendingKey, endpointService: ZcashEndpointService?) {
        self.synchronizer = synchronizer
        self.accountUUID = accountUUID
        self.spendingKey = spendingKey
        self.endpointService = endpointService
    }

    func quote() async throws -> (amount: Zatoshi, fee: Zatoshi) {
        let proposal = try await synchronizer.proposeImmediateMigration(accountUUID: accountUUID)
        return (proposal.amount, proposal.fee)
    }

    // An ordinary send-max over the same broadcaster path as every send; the SDK migration store is
    // told about the sweep afterwards so it does not re-offer the migration while the tx is unmined.
    func migrate() async throws -> String? {
        // re-propose: the balance may have moved since the confirmation screen was shown
        let immediate = try await synchronizer.proposeImmediateMigration(accountUUID: accountUUID)
        let created = try await synchronizer.broadcaster.createProposedTransactions(proposal: immediate.proposal, spendingKey: spendingKey)
        guard let endpoint = endpointService?.currentEndpoint else {
            throw AppError.ZcashError.noAccountId
        }

        let outcomes: [(txId: Data, outcome: TransactionSubmissionOutcome)]
        do {
            outcomes = try await ZcashOperationGuard.shared.withSubmission(timeout: 30) {
                await ZcashSendService.submit(created: created, via: synchronizer.broadcaster, endpoint: endpoint)
            }
        } catch is ZcashOperationGuard.Failure {
            await synchronizer.broadcaster.releaseForResubmission(transactions: created, to: [endpoint])
            return created.first?.txId.toHexStringTxId()
        }

        if let accepted = outcomes.first(where: { if case .accepted = $0.outcome { return true } else { return false } }) {
            // bookkeeping only: a failed record never turns a landed broadcast into a failure
            try? await synchronizer.recordImmediateMigration(accountUUID: accountUUID, txid: accepted.txId)
        }

        let mapped = ZcashSendService.submitOutcomes(outcomes)
        if let submitFailure = mapped.submitFailure {
            throw submitFailure
        }
        return mapped.txIds.first
    }
}

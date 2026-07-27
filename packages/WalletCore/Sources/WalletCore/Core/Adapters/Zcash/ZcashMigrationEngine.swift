import Foundation
import ZcashLightClientKit

protocol IZcashMigrationEngine: AnyObject {
    // Propose a send-max sweep of the account's spendable shielded funds to its own Unified Address
    // and return the fee the proposal requires. Used by the confirmation screen (amount = balance − fee).
    func estimatedFee() async throws -> Zatoshi
    // Re-propose fresh and execute the send-max sweep, returning the first broadcast txid (display hex),
    // or nil if no transaction landed.
    func migrate() async throws -> String?
}

final class ZcashMigrationEngine: IZcashMigrationEngine {
    private let synchronizer: Synchronizer
    private let accountUUID: AccountUUID
    private let spendingKey: UnifiedSpendingKey

    init(synchronizer: Synchronizer, accountUUID: AccountUUID, spendingKey: UnifiedSpendingKey) {
        self.synchronizer = synchronizer
        self.accountUUID = accountUUID
        self.spendingKey = spendingKey
    }

    func estimatedFee() async throws -> Zatoshi {
        try await proposal().totalFeeRequired()
    }

    func migrate() async throws -> String? {
        // re-propose: the balance may have moved since the confirmation screen was shown
        let proposal = try await proposal()

        let stream = try await synchronizer.createProposedTransactions(proposal: proposal, spendingKey: spendingKey)

        // A send-max over [Sapling, Orchard] under ZIP-317 can be multi-step. Drive the whole stream to
        // completion exactly like ZcashAdapter.send — never break early, otherwise the remaining steps are
        // never pulled → never signed → never broadcast. The SDK persists every created tx, so the normal
        // resubmit/reSync path keeps them alive across backgrounding.
        var txIds: [String] = []
        var iterator = stream.makeAsyncIterator()
        for _ in 0 ..< proposal.transactionCount() {
            guard let result = try await iterator.next() else { continue }
            switch result {
            case let .success(txId: id),
                 let .grpcFailure(txId: id, error: _),
                 let .submitFailure(txId: id, code: _, description: _),
                 let .notAttempted(txId: id):
                txIds.append(id.toHexStringTxId())
            }
        }
        return txIds.first
    }

    // official Orchard→Ironwood migration (2.7.0-rc.1): migrates the account's entire Orchard balance
    // into the Ironwood pool.
    private func proposal() async throws -> Proposal {
        try await synchronizer.proposeOrchardToIronwoodMigration(accountUUID: accountUUID)
    }
}

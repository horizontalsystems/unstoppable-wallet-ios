import Foundation

// Durable per-wallet markers for transactions the node terminally rejected (code -25).
// Persists only txid/network/reason/expiry: no raw tx, addresses, memos or node error text.
class ZcashTerminalResubmissionStore {
    private let uniqueId: String
    private let network: String
    private let storage: ZcashAdapterStorage

    init(uniqueId: String, network: String, storage: ZcashAdapterStorage) {
        self.uniqueId = uniqueId
        self.network = network
        self.storage = storage
    }

    // per-call GRDB read, no cache: the table holds a handful of rows and dbPool is
    // thread-safe by itself (same pattern as ZcashMigrator.isMigrationTx)
    private func records() -> [ZcashTerminalResubmission] {
        ((try? storage.terminalResubmissions(accountId: uniqueId)) ?? []).filter { $0.network == network }
    }

    func isMarked(txId: String) -> Bool {
        records().contains { $0.txId == txId }
    }

    func markNodeRejected(txId: String, expiryHeight: Int) {
        try? storage.save(terminalResubmission: ZcashTerminalResubmission(accountId: uniqueId, txId: txId, network: network, reason: .nodeRejected, expiryHeight: expiryHeight))
    }

    // Removes markers whose transaction is gone or mined (not among active unmined txs)
    // or already expired; such a tx can never be resubmitted again anyway.
    func prune(activeUnminedTxIds: Set<String>, latestHeight: Int) {
        let obsoleteTxIds = records().filter { record in
            !activeUnminedTxIds.contains(record.txId) || (latestHeight > 0 && record.expiryHeight > 0 && record.expiryHeight <= latestHeight)
        }.map(\.txId)

        guard !obsoleteTxIds.isEmpty else {
            return
        }
        try? storage.deleteTerminalResubmissions(accountId: uniqueId, txIds: obsoleteTxIds)
    }
}

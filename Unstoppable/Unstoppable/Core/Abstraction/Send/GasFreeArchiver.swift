import Foundation

/// Persists a submitted GasFree transfer as a `PendingGasFreeTransferRecord`.
/// One concern, one method — Sender stays a thin orchestrator.
struct GasFreeArchiver {
    let smartAccountManager: SmartAccountManager

    /// Build the record from `(account, prepared, status)` and save. Caller decides
    /// whether to surface the throw — see `GasFreeSender.submit` for the post-submit
    /// "do { try archive } catch { log }" rationale.
    func archive(account: Account, prepared: PreparedGasFreeTransfer, status: GasFreeProvider.TransferStatus) throws {
        let record = PendingGasFreeTransferRecord(
            traceId: status.id,
            accountId: account.id,
            token: prepared.token.base58,
            value: prepared.value.description,
            receiver: prepared.receiver.base58,
            txnHash: status.txnHash,
            status: status.state.rawString,
            submittedAt: Date().timeIntervalSince1970,
            lastPolledAt: nil
        )
        try smartAccountManager.savePendingGasFreeTransfer(record: record)
    }
}

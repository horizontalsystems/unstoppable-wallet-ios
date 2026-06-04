import Foundation

// Per-txHash worker: re-submits one OCP proof until delivered (or terminal/expired). Foreground-only, own 30s period.
class OpenCryptoPayProofWorker: IAppWorker {
    let id: String
    let interval: TimeInterval = 30

    private let record: OpenCryptoPayPaymentRecord
    private let manager: OpenCryptoPayPaymentManager
    private let submitter: OpenCryptoPaySubmitter
    private let maxAgeSeconds: TimeInterval = 7 * 24 * 3600

    init(record: OpenCryptoPayPaymentRecord, manager: OpenCryptoPayPaymentManager, submitter: OpenCryptoPaySubmitter) {
        id = record.transactionHash
        self.record = record
        self.manager = manager
        self.submitter = submitter
    }

    func run() async -> Bool {
        // Idempotency: inline submit or a sibling pass may have already resolved this proof.
        let fresh: OpenCryptoPayPaymentRecord?
        do {
            fresh = try manager.record(transactionHash: record.transactionHash, accountId: record.accountId)
        } catch {
            return false // transient DB read error → retry next interval, don't self-terminate
        }
        guard let fresh else {
            return true
        }
        guard fresh.proofStatus == .pending else {
            return true
        }

        let now = Date().timeIntervalSince1970
        if now - record.createdAt > maxAgeSeconds {
            manager.markFailed(transactionHash: record.transactionHash, accountId: record.accountId)
            return true
        }
        guard let callback = URL(string: record.callback) else {
            return true
        }

        manager.markAttempted(transactionHash: record.transactionHash, accountId: record.accountId, at: now)

        do {
            try await submitter.submit(callback: callback, quote: record.quoteId, method: record.method, proof: .tx(record.transactionHash))
            manager.markSubmitted(transactionHash: record.transactionHash, accountId: record.accountId)
            return true
        } catch {
            if OpenCryptoPaySubmitError.isTerminal(error) {
                manager.markFailed(transactionHash: record.transactionHash, accountId: record.accountId)
                return true
            }
            return false
        }
    }
}

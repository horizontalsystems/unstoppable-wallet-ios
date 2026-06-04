import Foundation
import GRDB

struct OpenCryptoPayPaymentRecord: Codable, FetchableRecord, PersistableRecord {
    static let databaseTableName = "opencryptopay_payments"

    let accountId: String
    let transactionHash: String
    let paymentId: String
    let quoteId: String
    let callback: String
    let method: String
    let merchant: String?
    let createdAt: Double
    var proofSubmittedAt: Double?
    var proofFailedAt: Double?
    var lastAttemptedAt: Double?

    enum Columns: String, ColumnExpression {
        case accountId, transactionHash, paymentId, quoteId, callback, method, merchant, createdAt, proofSubmittedAt, proofFailedAt, lastAttemptedAt
    }

    enum ProofStatus: String {
        case submitted, pending, reconciliation

        var localizedTitle: String {
            "open_crypto_pay.tx_info.proof_status.\(rawValue)".localized
        }
    }

    // proofSubmittedAt has priority; markSubmitted always clears proofFailedAt, so both never coexist.
    var proofStatus: ProofStatus {
        if proofSubmittedAt != nil { return .submitted }
        if proofFailedAt != nil { return .reconciliation }
        return .pending
    }
}

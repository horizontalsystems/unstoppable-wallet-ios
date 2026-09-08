import Foundation

// Resource-exhaustion guards for untrusted dApp requests (mirrors Android WCSolanaHelper): a request is
// size- and count-bounded BEFORE any base64/base58 decode or signing, so a malicious dApp can't drive
// unbounded decode work (Base58 is O(n²)) or exhaust the heap.
enum WCNSolanaLimits {
    // a Solana transaction is at most 1232 bytes (packet MTU) ≈ 1644 base64 chars; cap with headroom
    static let maxTransactionBase64Length = 2048
    // signAllTransactions batches are small in practice
    static let maxTransactionsPerRequest = 32
    // upper bound on a single string param (message / raw JSON) before per-item caps apply
    static let maxParamsLength = 128 * 1024
}

enum SendTransactionError: Error {
    case connection
    case noFee
    case unknown
}

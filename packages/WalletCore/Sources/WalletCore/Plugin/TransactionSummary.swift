/// A chain plugin's transaction, described without kit types. The generic list, info, rate and
/// spam code render it, so a plugin supplies no view code for an ordinary transfer or contract call.
/// Built by the plugin per record, on demand.
struct TransactionSummary {
    enum Kind {
        case send(value: AppValue, to: String, sentToSelf: Bool, memo: String?)
        case receive(value: AppValue, from: String, memo: String?)
        /// Any other transaction with the account's net movement per asset: none for a call that moved
        /// nothing, several for a swap or a wrap.
        case contractCall(contract: String, method: String?, incoming: [TransferEvent], outgoing: [TransferEvent])
    }

    let kind: Kind
    /// What the account paid for the transaction; nil when someone else paid.
    let fee: AppValue?
    /// The account signed it. Only then are its outgoing legs the account's own for the spam cache.
    let signedByAccount: Bool
    /// It never reached the chain (expired before inclusion): the status row reads "not processed".
    let notProcessed: Bool
}

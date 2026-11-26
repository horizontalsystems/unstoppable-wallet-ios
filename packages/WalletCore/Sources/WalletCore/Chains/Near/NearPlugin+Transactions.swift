extension NearPlugin: TransactionPresentationCapability {
    func summary(record: TransactionRecord) -> TransactionSummary? {
        guard let record = record as? NearTransactionRecord else {
            return nil
        }

        let kind: TransactionSummary.Kind
        switch record.type {
        case let .send(value, to, sentToSelf, memo):
            kind = .send(value: value, to: to, sentToSelf: sentToSelf, memo: memo)
        case let .receive(value, from, memo):
            kind = .receive(value: value, from: from, memo: memo)
        case let .contractCall(contractId, method, incoming, outgoing):
            kind = .contractCall(contract: contractId, method: method, incoming: incoming, outgoing: outgoing)
        }

        return TransactionSummary(
            kind: kind,
            // gas the account paid; nil when someone else signed the transaction
            fee: record.fee,
            // what the account signed is its own: its outgoing legs are not an attempt to mislead
            signedByAccount: record.signed,
            // never included before its block hash expired: nothing happened on chain
            notProcessed: record.expired
        )
    }
}

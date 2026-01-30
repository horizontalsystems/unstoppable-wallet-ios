// Extracts "to" address from outgoing transaction records
class OutputTransactionFactory {
    func cachedOutput(from record: TransactionRecord) -> CachedOutputTransaction? {
        guard let address = extractToAddress(from: record) else {
            return nil
        }

        return CachedOutputTransaction(
            address: address,
            timestamp: Int(record.date.timeIntervalSince1970),
            blockHeight: record.blockHeight
        )
    }

    private func extractToAddress(from record: TransactionRecord) -> String? {
        switch record {
        case let record as EvmOutgoingTransactionRecord:
            return record.to

        case let record as TronOutgoingTransactionRecord:
            return record.to

        case let record as StellarTransactionRecord:
            if case let .sendPayment(_, to, _) = record.type {
                return to
            }
            return nil

        case let record as ExternalContractCallTransactionRecord:
            if let event = record.outgoingEvents.first {
                return event.address
            }
            return nil

        case let record as TronExternalContractCallTransactionRecord:
            if let event = record.outgoingEvents.first {
                return event.address
            }
            return nil

        case let record as ContractCallTransactionRecord:
            if let event = record.outgoingEvents.first {
                return event.address
            }
            return nil

        default:
            return nil
        }
    }
}

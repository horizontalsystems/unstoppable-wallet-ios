import Foundation
import MarketKit

class OutputTransactionFactory {
    /// Returns outgoing addresses from record.
    /// - Returns: nil if record is not outgoing;
    ///            empty array if outgoing but no extractable addresses (Bitcoin/Monero UTXO);
    ///            non-empty array with destination addresses
    static func outgoingAddresses(from record: TransactionRecord) -> [String]? {
        switch record {
        case let r as EvmOutgoingTransactionRecord:
            return [r.to]

        case let r as TronOutgoingTransactionRecord:
            return [r.to]

        case let r as StellarTransactionRecord:
            if case let .sendPayment(_, to, _) = r.type {
                return [to]
            }
            return nil

        case let r as ExternalContractCallTransactionRecord:
            let addresses = filterZeroPoisoningEvents(r.outgoingEvents).map(\.address)
            return addresses.isEmpty ? nil : addresses

        case let r as TronExternalContractCallTransactionRecord:
            let addresses = filterZeroPoisoningEvents(r.outgoingEvents).map(\.address)
            return addresses.isEmpty ? nil : addresses

        case let r as ContractCallTransactionRecord:
            let addresses = r.outgoingEvents.map(\.address)
            return addresses.isEmpty ? nil : addresses

        case let r as TronContractCallTransactionRecord:
            let addresses = r.outgoingEvents.map(\.address)
            return addresses.isEmpty ? nil : addresses

        default:
            return nil
        }
    }

    private static func filterZeroPoisoningEvents(_ events: [TransferEvent]) -> [TransferEvent] {
        events.filter { !$0.value.zeroValue }
    }

    /// Creates CachedOutputTransaction entries from a TransactionRecord
    func cachedOutputs(from record: TransactionRecord) -> [CachedOutputTransaction] {
        guard let addresses = Self.outgoingAddresses(from: record) else {
            return []
        }

        let timestamp = Int(record.date.timeIntervalSince1970)
        let blockHeight = record.blockHeight

        return addresses.map {
            CachedOutputTransaction(address: $0, timestamp: timestamp, blockHeight: blockHeight)
        }
    }
}

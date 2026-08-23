import Foundation
import MarketKit

class OutputTransactionFactory {
    /// Returns addresses the user sent to, for records the user initiated.
    /// Such records are trusted without scoring.
    /// - Returns: nil if the record is not the user's own send;
    ///            empty array if it is but has no extractable addresses;
    ///            non-empty array with destination addresses
    static func outgoingAddresses(from record: TransactionRecord) -> [String]? {
        switch record {
        case let r as EvmOutgoingTransactionRecord:
            return [r.to]

        case let r as TronOutgoingTransactionRecord:
            return [r.to]

        case let r as StellarTransactionRecord:
            let recipients = ([r.type] + r.additionalActions).compactMap { action -> String? in
                switch action {
                case let .sendPayment(_, to, _): return to
                case let .accountFunded(_, account): return account
                default: return nil
                }
            }
            return recipients.isEmpty ? nil : recipients

        case let r as SolanaOutgoingTransactionRecord:
            guard !r.sentToSelf, let to = r.to else {
                return nil
            }
            return [to]

        case let r as ContractCallTransactionRecord:
            return r.outgoingEvents.map(\.address)

        case let r as TronContractCallTransactionRecord:
            return r.outgoingEvents.map(\.address)

        default:
            return nil
        }
    }

    // Counterparties of every other record: the recipient of a sent leg, otherwise the sender
    // of a received one. Poisoning routinely mimics whoever just paid the user, and a watch-only
    // wallet has no outgoing history at all, so senders are correlation context too.
    static func counterpartyAddresses(from record: TransactionRecord) -> [String] {
        switch record {
        case let r as EvmIncomingTransactionRecord:
            return [r.from]

        case let r as TronIncomingTransactionRecord:
            return [r.from]

        case let r as StellarTransactionRecord:
            return ([r.type] + r.additionalActions).compactMap { action -> String? in
                switch action {
                case let .receivePayment(_, from): return from
                case let .accountCreated(_, funder): return funder
                default: return nil
                }
            }

        case let r as SolanaIncomingTransactionRecord:
            return r.from.map { [$0] } ?? []

        case let r as SolanaUnknownTransactionRecord:
            let incoming = r.incomingTransfers.compactMap(\.address)
            return incoming.isEmpty ? r.outgoingTransfers.compactMap(\.address) : incoming

        case let r as ExternalContractCallTransactionRecord:
            return sentElseReceived(outgoing: filterZeroPoisoningEvents(r.outgoingEvents), incoming: r.incomingEvents)

        case let r as TronExternalContractCallTransactionRecord:
            return sentElseReceived(outgoing: filterZeroPoisoningEvents(r.outgoingEvents), incoming: r.incomingEvents)

        case let r as ContractCallTransactionRecord:
            return r.incomingEvents.map(\.address)

        case let r as TronContractCallTransactionRecord:
            return r.incomingEvents.map(\.address)

        default:
            return []
        }
    }

    private static func sentElseReceived(outgoing: [TransferEvent], incoming: [TransferEvent]) -> [String] {
        let sent = outgoing.map(\.address)
        return sent.isEmpty ? incoming.map(\.address) : sent
    }

    private static func filterZeroPoisoningEvents(_ events: [TransferEvent]) -> [TransferEvent] {
        events.filter {
            switch $0.value.kind { // check if token not is coinGecko (not valid)
            case .raw, .eip20Token: return false
            default: ()
            }

            return !$0.value.zeroValue // check if sended balance != 0
        }
    }

    /// Creates CachedOutputTransaction entries from a TransactionRecord
    func cachedOutputs(from record: TransactionRecord) -> [CachedOutputTransaction] {
        let outgoing = Self.outgoingAddresses(from: record) ?? []
        let addresses = outgoing.isEmpty ? Self.counterpartyAddresses(from: record) : outgoing

        let timestamp = Int(record.date.timeIntervalSince1970)
        // Solana records carry 0 as a confirmed placeholder (the kit stores no slot);
        // only a real height may feed block correlation
        let blockHeight = record.blockHeight.flatMap { $0 > 0 ? $0 : nil }

        return addresses.map {
            CachedOutputTransaction(address: $0, timestamp: timestamp, blockHeight: blockHeight)
        }
    }
}

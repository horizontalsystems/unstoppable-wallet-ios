import BigInt
import EvmKit
import Foundation
import MarketKit
import StellarKit

class SpamTransactionInfoFactory {
    private let eventFactory: TransferEventFactory
    
    init(eventFactory: TransferEventFactory = TransferEventFactory()) {
        self.eventFactory = eventFactory
    }
    
    func spamTransactionInfo(from record: TransactionRecord) -> SpamTransactionInfo? {
        let events = eventFactory.transferEvents(transactionRecord: record)
        
        guard !events.isEmpty else {
            return nil
        }
        
        return SpamTransactionInfo(
            hash: record.transactionHash,
            blockchainType: record.source.blockchainType,
            timestamp: Int(record.date.timeIntervalSince1970),
            blockHeight: record.blockHeight,
            events: events
        )
    }
}

class TransferEventFactory {
    func transferEvents(transactionRecord: TransactionRecord) -> TransferEvents {
        switch transactionRecord {
        case let record as EvmIncomingTransactionRecord:
            return .init(incoming: [.init(address: record.from, value: record.value)])
        case let record as ExternalContractCallTransactionRecord:
            return .init(incoming: record.incomingEvents, outgoing: record.outgoingEvents)
        case let record as StellarTransactionRecord:
            return .init(incoming: StellarTransactionRecord.doubtfulEvents(type: record.type))
        case let record as TronExternalContractCallTransactionRecord:
            return .init(incoming: record.incomingEvents, outgoing: record.outgoingEvents)
        case let record as TronIncomingTransactionRecord:
            return .init(incoming: [.init(address: record.from, value: record.value)])
        default: return .init()
        }
    }
}

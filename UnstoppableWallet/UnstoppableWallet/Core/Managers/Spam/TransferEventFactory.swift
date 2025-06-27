import BigInt
import EvmKit
import Foundation
import MarketKit
import StellarKit

class TransferEventFactory {
    func transferEvents(transactionRecord: TransactionRecord) -> [TransferEvent] {
        switch transactionRecord {
        case let record as EvmIncomingTransactionRecord:
            return [.init(address: record.from, value: record.value)]
        case let record as ExternalContractCallTransactionRecord:
            return record.incomingEvents + record.outgoingEvents
        case let record as StellarTransactionRecord:
            return StellarTransactionRecord.doubtfulEvents(type: record.type)
        case let record as TronExternalContractCallTransactionRecord:
            return record.incomingEvents + record.outgoingEvents
        case let record as TronIncomingTransactionRecord:
            return [.init(address: record.from, value: record.value)]
        default: return []
        }
    }
}

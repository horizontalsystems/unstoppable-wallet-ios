import Foundation
import EthereumKit
import MarketKit

class ContractCallIncomingTransactionRecord: EvmTransactionRecord {
    let baseCoinValue: TransactionValue?
    let events: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin, baseCoinValue: TransactionValue?, events: [TransferEvent]) {
        self.baseCoinValue = baseCoinValue
        self.events = events

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: true)
    }

    override var mainValue: TransactionValue? {
        if let baseCoinValue = baseCoinValue, events.isEmpty {
            return baseCoinValue
        } else if baseCoinValue == nil, events.count == 1 {
            return events[0].value
        } else {
            return nil
        }
    }

}

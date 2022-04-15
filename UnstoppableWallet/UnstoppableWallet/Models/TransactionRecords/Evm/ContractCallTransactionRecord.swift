import Foundation
import EthereumKit
import MarketKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    let contractAddress: String
    let method: String?
    let totalValue: TransactionValue
    let incomingEip20Events: [TransferEvent]
    let outgoingEip20Events: [TransferEvent]

    init(source: TransactionSource, transaction: Transaction, baseCoin: PlatformCoin,
         contractAddress: String, method: String?, totalValue: TransactionValue, incomingEip20Events: [TransferEvent], outgoingEip20Events: [TransferEvent]) {
        self.contractAddress = contractAddress
        self.method = method
        self.totalValue = totalValue
        self.incomingEip20Events = incomingEip20Events
        self.outgoingEip20Events = outgoingEip20Events

        super.init(source: source, transaction: transaction, baseCoin: baseCoin, ownTransaction: true)
    }

    override var mainValue: TransactionValue? {
        var incomingValues = [TransactionValue]()
        var outgoingValues = [TransactionValue]()

        if let decimalValue = totalValue.decimalValue, decimalValue != 0 {
            if decimalValue > 0 {
                incomingValues.append(totalValue)
            } else {
                outgoingValues.append(totalValue)
            }
        }

        for event in incomingEip20Events {
            incomingValues.append(event.value)
        }
        for event in outgoingEip20Events {
            outgoingValues.append(event.value)
        }

        if incomingValues.count == 1, outgoingValues.isEmpty {
            return incomingValues[0]
        } else if incomingValues.isEmpty, outgoingValues.count == 1 {
            return outgoingValues[0]
        } else {
            return nil
        }
    }

}

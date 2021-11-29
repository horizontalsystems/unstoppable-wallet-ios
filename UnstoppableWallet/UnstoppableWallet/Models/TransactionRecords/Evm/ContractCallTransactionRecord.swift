import Foundation
import EthereumKit
import MarketKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    typealias AddressTransactionValue = (address: String, value: TransactionValue)

    let contractAddress: String
    let method: String?
    let value: TransactionValue
    let incomingInternalETHs: [AddressTransactionValue]
    let incomingEip20Events: [AddressTransactionValue]
    let outgoingEip20Events: [AddressTransactionValue]

    init(source: TransactionSource, fullTransaction: FullTransaction, baseCoin: PlatformCoin,
         contractAddress: String, method: String?, value: Decimal, incomingInternalETHs: [AddressTransactionValue], incomingEip20Events: [AddressTransactionValue], outgoingEip20Events: [AddressTransactionValue],
         foreignTransaction: Bool = false) {
        self.contractAddress = contractAddress
        self.method = method
        self.value = .coinValue(platformCoin: baseCoin, value: value)
        self.incomingInternalETHs = incomingInternalETHs
        self.incomingEip20Events = incomingEip20Events
        self.outgoingEip20Events = outgoingEip20Events

        super.init(source: source, fullTransaction: fullTransaction, baseCoin: baseCoin, foreignTransaction: foreignTransaction)
    }

}

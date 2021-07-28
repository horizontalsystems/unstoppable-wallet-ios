import Foundation
import EthereumKit
import CoinKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    typealias IncomingInternalETH = (from: String, value: CoinValue)
    typealias IncomingEip20Event = (from: String, value: CoinValue)
    typealias OutgoingEip20Event = (to: String, value: CoinValue)

    let contractAddress: String
    let method: String?
    let value: CoinValue
    let incomingInternalETHs: [IncomingInternalETH]
    let incomingEip20Events: [IncomingEip20Event]
    let outgoingEip20Events: [OutgoingEip20Event]

    init(fullTransaction: FullTransaction, baseCoin: Coin,
         contractAddress: String, method: String?, value: Decimal, incomingInternalETHs: [IncomingInternalETH], incomingEip20Events: [IncomingEip20Event], outgoingEip20Events: [OutgoingEip20Event],
         foreignTransaction: Bool = false) {
        self.contractAddress = contractAddress
        self.method = method
        self.value = CoinValue(coin: baseCoin, value: value)
        self.incomingInternalETHs = incomingInternalETHs
        self.incomingEip20Events = incomingEip20Events
        self.outgoingEip20Events = outgoingEip20Events

        super.init(fullTransaction: fullTransaction, baseCoin: baseCoin, foreignTransaction: foreignTransaction)
    }

}

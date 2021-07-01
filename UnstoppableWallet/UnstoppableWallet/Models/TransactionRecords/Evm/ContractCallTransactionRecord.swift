import Foundation
import EthereumKit
import CoinKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    let contractAddress: String
    let method: String?

    init(fullTransaction: FullTransaction, baseCoin: Coin, contractAddress: String, method: String?) {
        self.contractAddress = contractAddress
        self.method = method

        super.init(fullTransaction: fullTransaction, baseCoin: baseCoin)
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .contractCall(contractAddress: contractAddress, method: method)
    }

}

import Foundation
import EthereumKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    let contractAddress: String
    let method: String?

    init(fullTransaction: FullTransaction, contractAddress: String, method: String?) {
        self.contractAddress = contractAddress
        self.method = method

        super.init(fullTransaction: fullTransaction)
    }

    override func type(lastBlockInfo: LastBlockInfo?) -> TransactionType {
        .contractCall(contractAddress: contractAddress, method: method)
    }

}

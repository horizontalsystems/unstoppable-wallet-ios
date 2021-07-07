import Foundation
import EthereumKit
import CoinKit

class ContractCallTransactionRecord: EvmTransactionRecord {
    let contractAddress: String
    let method: String?

    init(fullTransaction: FullTransaction, baseCoin: Coin, contractAddress: String, method: String?, foreignTransaction: Bool = false) {
        self.contractAddress = contractAddress
        self.method = method

        super.init(fullTransaction: fullTransaction, baseCoin: baseCoin, foreignTransaction: foreignTransaction)
    }

}

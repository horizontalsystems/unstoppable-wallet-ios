import BigInt
import Foundation
import MarketKit
import WalletConnectSign

class WCNEvmTransactionParsed: WCNParsedRequest {
    static let sendMethod = "eth_sendTransaction"
    static let signMethod = "eth_signTransaction"

    let transaction: WCNEvmTransaction
    let blockchainType: BlockchainType
    let baseToken: Token
    private let swapInfo: WCNSwapInfo?

    init(request: Request, transaction: WCNEvmTransaction, blockchainType: BlockchainType, baseToken: Token, swapInfo: WCNSwapInfo?) {
        self.transaction = transaction
        self.blockchainType = blockchainType
        self.baseToken = baseToken
        self.swapInfo = swapInfo
        super.init(request: request, kind: .transaction, from: transaction.from.eip55)
    }

    override var isSignOnly: Bool { method == Self.signMethod }
    override var to: String? { transaction.to.eip55 }
    override var value: BigUInt? { transaction.value }
    override var data: Data? { transaction.data }
    override var decodedSwapInfo: WCNSwapInfo? { swapInfo }

    override func makeSendData() -> SendData? {
        .evm(blockchainType: blockchainType, transactionData: transaction.transactionData, token: baseToken)
    }
}

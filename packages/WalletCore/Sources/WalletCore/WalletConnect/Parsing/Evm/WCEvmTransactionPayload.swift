import BigInt
import Foundation
import MarketKit
import WalletConnectSign

class WCEvmTransactionPayload: WCRequestPayload {
    static let sendMethod = "eth_sendTransaction"
    static let signMethod = "eth_signTransaction"

    let transaction: WCEvmTransaction
    let blockchainType: BlockchainType
    let baseToken: Token
    private let swapInfo: WCSwapInfo?

    init(request: Request, transaction: WCEvmTransaction, blockchainType: BlockchainType, baseToken: Token, swapInfo: WCSwapInfo?) {
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
    override var decodedSwapInfo: WCSwapInfo? { swapInfo }

    override func makeSendData() -> SendData? {
        .evm(blockchainType: blockchainType, transactionData: transaction.transactionData, token: baseToken)
    }
}

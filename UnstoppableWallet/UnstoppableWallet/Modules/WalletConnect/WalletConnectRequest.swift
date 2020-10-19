import EthereumKit
import WalletConnect
import BigInt

class WalletConnectRequest {
    let id: Int

    init(id: Int) {
        self.id = id
    }

}

class WalletConnectSendEthereumTransactionRequest: WalletConnectRequest {
    let transaction: WalletConnectTransaction

    init(id: Int, transaction: WCEthereumTransaction) throws {
        self.transaction = WalletConnectTransaction(
                from: try Address(hex: transaction.from),
                to: try transaction.to.map { try Address(hex: $0) },
                nonce: transaction.nonce.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasPrice: transaction.gasPrice.flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                gasLimit: (transaction.gas ?? transaction.gasLimit).flatMap { Int($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                value: transaction.value.flatMap { BigUInt($0.replacingOccurrences(of: "0x", with: ""), radix: 16) },
                data: Data(hex: transaction.data)
        )

        super.init(id: id)
    }
}

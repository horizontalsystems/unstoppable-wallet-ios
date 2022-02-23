import EthereumKit

class EvmSyncSource {
    let name: String
    let rpcSource: RpcSource
    let transactionSource: EthereumKit.TransactionSource

    init(name: String, rpcSource: RpcSource, transactionSource: EthereumKit.TransactionSource) {
        self.name = name
        self.rpcSource = rpcSource
        self.transactionSource = transactionSource
    }

}

extension EvmSyncSource: Equatable {

    static func ==(lhs: EvmSyncSource, rhs: EvmSyncSource) -> Bool {
        lhs.name == rhs.name
    }

}

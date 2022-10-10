import EvmKit

class EvmSyncSource {
    let name: String
    let rpcSource: RpcSource
    let transactionSource: EvmKit.TransactionSource

    init(name: String, rpcSource: RpcSource, transactionSource: EvmKit.TransactionSource) {
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

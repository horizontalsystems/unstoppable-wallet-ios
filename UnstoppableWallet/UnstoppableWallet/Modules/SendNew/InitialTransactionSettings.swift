import EvmKit

enum InitialTransactionSettings {
    case evm(gasPrice: GasPrice?, nonce: Int?)
}

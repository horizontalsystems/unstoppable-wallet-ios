import BigInt
import EvmKit

enum InitialTransactionSettings {
    case evm(gasPrice: GasPrice?, nonce: Int?)
    case aa(maxFeePerGas: BigUInt?, maxPriorityFeePerGas: BigUInt?, nonce: BigUInt?)
}

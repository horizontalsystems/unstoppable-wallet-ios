import EvmKit

enum TransactionSettings {
    case evm(gasPrice: GasPrice, nonce: Int?)
    case bitcoin(satoshiPerByte: Int)

    var gasPrice: GasPrice? {
        switch self {
        case let .evm(gasPrice, _): return gasPrice
        default: return nil
        }
    }

    var nonce: Int? {
        switch self {
        case let .evm(_, nonce): return nonce
        default: return nil
        }
    }
}

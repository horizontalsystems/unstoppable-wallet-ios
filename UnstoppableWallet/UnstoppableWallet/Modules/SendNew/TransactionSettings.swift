import EvmKit

enum TransactionSettings {
    case evm(gasPriceData: GasPriceData, nonce: Int?)
    case bitcoin(satoshiPerByte: Int)

    var gasPriceData: GasPriceData? {
        switch self {
        case let .evm(gasPriceData, _): return gasPriceData
        default: return nil
        }
    }

    var nonce: Int? {
        switch self {
        case let .evm(_, nonce): return nonce
        default: return nil
        }
    }

    var satoshiPerByte: Int? {
        switch self {
        case let .bitcoin(satoshiPerByte): return satoshiPerByte
        default: return nil
        }
    }
}

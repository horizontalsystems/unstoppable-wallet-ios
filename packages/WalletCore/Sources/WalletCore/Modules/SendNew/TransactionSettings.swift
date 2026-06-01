import BigInt
import EvmKit
import MoneroKit
import ZcashLightClientKit

enum TransactionSettings {
    case evm(gasPriceData: GasPriceData, nonce: Int?)
    case bitcoin(satoshiPerByte: Int)
    case monero(priority: MoneroKit.SendPriority)
    case aa(maxFeePerGas: BigUInt, maxPriorityFeePerGas: BigUInt, nonce: BigUInt)
    case zcash(zip317MarginalFee: Zatoshi)

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

    var moneroPriority: MoneroKit.SendPriority? {
        switch self {
        case let .monero(priority): return priority
        default: return nil
        }
    }

    var zcashZip317MarginalFee: Zatoshi? {
        switch self {
        case let .zcash(zip317MarginalFee): return zip317MarginalFee
        default: return nil
        }
    }
}

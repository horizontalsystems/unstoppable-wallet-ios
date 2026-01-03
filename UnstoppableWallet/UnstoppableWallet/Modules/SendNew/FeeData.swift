import BitcoinCore
import Foundation
import TronKit

enum FeeData {
    case evm(evmFeeData: EvmFeeData)
    case bitcoin(params: SendParameters)
    case monero(amount: MoneroSendAmount, address: String)
    case tron(fees: [Fee])
    case zcash(fee: Decimal)

    var gasLimit: Int? {
        switch self {
        case let .evm(evmFeeData): return evmFeeData.gasLimit
        default: return nil
        }
    }
}

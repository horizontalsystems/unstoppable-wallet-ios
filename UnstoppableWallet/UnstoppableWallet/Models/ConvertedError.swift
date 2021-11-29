import BitcoinCore
import BinanceChainKit
import Erc20Kit
import EthereumKit
import HdWalletKit
import Hodler
import HsToolKit
import OneInchKit

// use convertedError to convert user relevant errors from kits to show them localized in UI
// localize converted error via AppError
// other errors prevented either in the Kit logic or via business logic of the app but need to be shown in debug routine

protocol ConvertibleError {
    var convertedError: Error { get }
}

extension Error {

    var convertedError: Error {
        if let error = self as? ConvertibleError {
            return error.convertedError
        }
        return self
    }

}

// converted errors

extension NetworkManager.RequestError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .noResponse: return AppError.noConnection
        default: return self
        }
    }
}

extension BinanceError: ConvertibleError {
    var convertedError: Error {
        if message.contains("requires non-empty memo in transfer transaction") {
            return AppError.binance(reason: .memoRequired)
        } else if message.contains("requires the memo contains only digits") {
            return AppError.binance(reason: .onlyDigitsAllowed)
        }

        return self
    }
}

extension Mnemonic.ValidationError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .invalidChecksum:
            return AppError.wordsChecksum
        default:
            return self
        }
    }
}

extension ReachabilityManager.ReachabilityError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .notReachable: return AppError.noConnection
        }
    }
}

extension EthereumKit.Kit.SyncError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .noNetworkConnection: return AppError.noConnection
        default: return self
        }
    }
}

extension EthereumKit.Address.ValidationError: ConvertibleError {
    var convertedError: Error {
         AppError.addressInvalid
    }
}

extension BinanceChainKit.CoderError: ConvertibleError {
    var convertedError: Error {
         AppError.addressInvalid
    }
}

extension HodlerPluginError: ConvertibleError {
    var convertedError: Error {
         AppError.notSupportedByHodler
    }
}

extension BitcoinCoreErrors.AddressConversionErrors: ConvertibleError {
    var convertedError: Error {
        AppError.addressInvalid
    }
}

extension HsToolKit.WebSocketStateError: ConvertibleError {
    var convertedError: Error {
        return AppError.noConnection
    }
}

extension EthereumKit.JsonRpcResponse.ResponseError: ConvertibleError {

    var convertedError: Error {
        switch self {
        case .rpcError(let rpcError):
            if rpcError.message == "insufficient funds for transfer" || rpcError.message.starts(with: "gas required exceeds allowance") {
                return AppError.ethereum(reason: .insufficientBalanceWithFee)
            }

            if rpcError.message.starts(with: "execution reverted") {
                return AppError.ethereum(reason: .executionReverted(message: rpcError.message))
            }

            if rpcError.message.contains("max fee per gas less than block base fee") {
                return AppError.ethereum(reason: .lowerThanBaseGasLimit)
            }

            return self
        default: return self
        }
    }

}

extension OneInchKit.Kit.SwapError: ConvertibleError {

    var convertedError: Error {
        switch self {
        case .notEnough: return AppError.oneInch(reason: .insufficientBalanceWithFee)
        case .cannotEstimate: return AppError.oneInch(reason: .cannotEstimate)
        }
    }

}

extension OneInchKit.Kit.QuoteError: ConvertibleError {

    var convertedError: Error {
        switch self {
            case .insufficientLiquidity: return AppError.oneInch(reason: .insufficientLiquidity)
        }
    }

}

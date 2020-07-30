import BitcoinCore
import BinanceChainKit
import FeeRateKit
import EosKit
import Erc20Kit
import EthereumKit
import HdWalletKit
import Hodler
import HsToolKit

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

extension BackendError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .selfTransfer: return AppError.eos(reason: .selfTransfer)
        case .accountNotExist: return AppError.eos(reason: .accountNotExist)
        case .insufficientRam: return AppError.eos(reason: .insufficientRam)
        default: return self
        }
    }
}

extension IncubedRpcApiProvider.IncubedError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .notReachable: return AppError.incubedNotReachable
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

extension WordsValidator.ValidationError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .emptyWords:
             return AppError.wordsValidation(reason: .emptyWords)
        case .invalidConfirmation:
            return AppError.wordsValidation(reason: .invalidConfirmation)
        }
    }
}

extension Mnemonic.ValidationError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .invalidWordsCount, .invalidWords:
            return AppError.wordsValidation(reason: .invalidWords)
        }
    }
}

extension EosKit.ValidationError: ConvertibleError {
    var convertedError: Error {
        switch self {
        case .invalidPrivateKey:
            return AppError.eos(reason: .invalidPrivateKey)
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

import Foundation

enum AppError: Error {
    case noConnection
    case invalidResponse(reason: String)
    case binance(reason: BinanceError)
    case zcash(reason: ZcashError)
    case ethereum(reason: EthereumError)
    case oneInch(reason: OneInchError)
    case invalidWords(count: Int)
    case wordsChecksum
    case addressInvalid
    case notSupportedByHodler
    case weakReference
    case unknownError

    enum BinanceError: Error {
        case memoRequired
        case onlyDigitsAllowed
    }

    enum ZcashError: Error {
        case sendToSelf
        case noReceiveAddress
    }

    enum EthereumError: Error {
        case insufficientBalanceWithFee
        case executionReverted(message: String)
        case lowerThanBaseGasLimit
    }

    enum OneInchError: Error {
        case insufficientBalanceWithFee
        case cannotEstimate
        case insufficientLiquidity
    }

}


extension AppError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .noConnection: return "alert.no_internet".localized
        case .invalidResponse(let reason): return reason
        case .binance(let reason):
            switch reason {
            case .memoRequired: return "error.send_binance.memo_required".localized
            case .onlyDigitsAllowed: return "error.send_binance.only_digits_allowed".localized
            }
        case .zcash(let reason):
            switch reason {
            case .sendToSelf: return "error.send.self_transfer".localized
            case .noReceiveAddress: return "send.error.invalid_address".localized
            }
        case .ethereum(let reason):
            switch reason {
            case .insufficientBalanceWithFee: return "" // localized in modules
            case .executionReverted(let message): return "ethereum_transaction.error.reverted".localized(message)
            case .lowerThanBaseGasLimit: return "ethereum_transaction.error.lower_than_base_gas_limit".localized
            }
        case .oneInch(let reason):
            switch reason {
            case .insufficientBalanceWithFee: return "" // localized in modules
            case .cannotEstimate: return "" // localized in modules
            case .insufficientLiquidity: return "swap.one_inch.error.insufficient_liquidity".localized
            }
        case .invalidWords(let count):
            return "restore_error.mnemonic_word_count".localized("\(count)")
        case .wordsChecksum:
            return "restore.checksum_error".localized
        case .addressInvalid: return "send.error.invalid_address".localized
        case .notSupportedByHodler: return "send.hodler_error.unsupported_address".localized
        case .weakReference: return "Weak Reference"
        case .unknownError: return "Unknown Error"
        }

    }

}

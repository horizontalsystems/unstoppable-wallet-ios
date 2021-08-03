import Foundation

enum AppError: Error {
    case noConnection
    case binance(reason: BinanceError)
    case zcash(reason: ZcashError)
    case ethereum(reason: EthereumError)
    case oneInch(reason: OneInchError)
    case wordsChecksum
    case addressInvalid
    case notSupportedByHodler
    case unknownError

    enum BinanceError: Error {
        case memoRequired
        case onlyDigitsAllowed
    }

    enum ZcashError: Error {
        case sendToSelf
    }

    enum EthereumError: Error {
        case insufficientBalanceWithFee
        case executionReverted(message: String)
    }

    enum OneInchError: Error {
        case insufficientBalanceWithFee
    }

}


extension AppError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .noConnection: return "alert.no_internet".localized
        case .binance(let reason):
            switch reason {
            case .memoRequired: return "error.send_binance.memo_required".localized
            case .onlyDigitsAllowed: return "error.send_binance.only_digits_allowed".localized
            }
        case .zcash(let reason):
            switch reason {
            case .sendToSelf: return "error.send.self_transfer".localized
            }
        case .ethereum(let reason):
            switch reason {
            case .insufficientBalanceWithFee: return "" // localized in modules
            case .executionReverted(let message): return "ethereum_transaction.error.reverted".localized(message)
            }
        case .oneInch(let reason):
            switch reason {
            case .insufficientBalanceWithFee: return "" // localized in modules
            }
        case .wordsChecksum:
            return "restore.checksum_error".localized
        case .addressInvalid: return "send.error.invalid_address".localized
        case .notSupportedByHodler: return "send.hodler_error.unsupported_address".localized
        case .unknownError: return "Unknown Error"
        }

    }

}

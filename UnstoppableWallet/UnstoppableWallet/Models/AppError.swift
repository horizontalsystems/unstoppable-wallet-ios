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
        case cantCreateKeys
        case noAccountId
        case noReceiveAddress
        case notEnough
        case seedRequired
    }

    enum EthereumError: Error {
        case insufficientBalanceWithFee
        case executionReverted(message: String)
        case lowerThanBaseGasLimit
        case nonceAlreadyInBlock
        case replacementTransactionUnderpriced
        case transactionUnderpriced
        case tipsHigherThanMaxFee
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
        case let .invalidResponse(reason): return reason
        case let .binance(reason):
            switch reason {
            case .memoRequired: return "error.send_binance.memo_required".localized
            case .onlyDigitsAllowed: return "error.send_binance.only_digits_allowed".localized
            }
        case let .zcash(reason):
            switch reason {
            case .sendToSelf: return "error.send.self_transfer".localized
            case .noAccountId: return "send.error.invalid_address".localized
            case .noReceiveAddress: return "send.error.invalid_address".localized
            case .notEnough: return "fee_settings.errors.insufficient_balance".localized
            case .seedRequired, .cantCreateKeys: return "Seed Required"
            }
        case let .ethereum(reason):
            switch reason {
            case .insufficientBalanceWithFee: return "" // localized in modules
            case let .executionReverted(message): return "ethereum_transaction.error.reverted".localized(message)
            case .lowerThanBaseGasLimit: return "ethereum_transaction.error.lower_than_base_gas_limit".localized
            case .nonceAlreadyInBlock: return "ethereum_transaction.error.nonce_already_in_block".localized
            case .replacementTransactionUnderpriced: return "ethereum_transaction.error.replacement_transaction_underpriced".localized
            case .transactionUnderpriced: return "ethereum_transaction.error.transaction_underpriced".localized
            case .tipsHigherThanMaxFee: return "ethereum_transaction.error.tips_higher_than_max_fee".localized
            }
        case let .oneInch(reason):
            switch reason {
            case .insufficientBalanceWithFee: return "" // localized in modules
            case .cannotEstimate: return "" // localized in modules
            case .insufficientLiquidity: return "swap.one_inch.error.insufficient_liquidity.info".localized
            }
        case let .invalidWords(count):
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

extension AppError {
    var title: String? {
        switch self {
        case .notSupportedByHodler: return "fee_settings.time_lock".localized
        default: return nil
        }
    }
}

extension Error {
    var title: String? {
        (convertedError as? AppError).flatMap(\.title)
    }
}

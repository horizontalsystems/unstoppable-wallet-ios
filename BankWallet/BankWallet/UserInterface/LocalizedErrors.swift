import Foundation
import HSHDWalletKit
import EosKit
import BitcoinCore
import BinanceChainKit

extension WordsValidator.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyWords:
            return "words_validator.empty_words".localized
        case .invalidConfirmation:
            return "words_validator.invalid_confirmation".localized
        }
    }
}

extension Mnemonic.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidWordsCount, .invalidWords:
            return "restore.validation_failed".localized
        }
    }
}

extension AccountCreator.CreateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .eosNotSupported:
            return "error.cant_create_eos".localized
        }
    }
}

extension EosKit.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPrivateKey:
            return "error.invalid_eos_key".localized
        }
    }
}

extension SendTransactionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connection: return "alert.no_internet".localized
        case .unknown: return "alert.network_issue".localized
        }
    }
}

extension EosAdapter.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidAccount: return "error.invalid_eos_account".localized
        }
    }
}

extension BackendError: LocalizedError {
    // not localized errors prevented via gui or business logic
    public var errorDescription: String? {
        switch self {
        case .selfTransfer: return "error.send_eos.self_transfer".localized
        case .accountNotExist: return "error.send_eos.account_not_exist".localized
        case .insufficientRam: return "error.send_eos.insufficient_ram".localized
        case .overdrawn: return "error.send_eos.overdraw"
        case .precisionMismatch: return "error.send_eos.precision_mismatch"
        case .wrongContract: return "error.send_eos.wrong_contract"
        case .unknown(let message): return "error.send_eos.unknown".localized(message)
        }
    }
}

extension ChartRateFactory.FactoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noRateStats: return "chart.error.no_statistics".localized
        case .noPercentDelta: return "chart.error.no_percentDelta".localized
        }
    }
}
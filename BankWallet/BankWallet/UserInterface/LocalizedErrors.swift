import Foundation
import HSHDWalletKit
import EosKit

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

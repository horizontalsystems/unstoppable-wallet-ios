import Foundation
import HSHDWalletKit

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
        return "restore.validation_failed".localized
    }
}

extension AccountCreator.CreateError: LocalizedError {
    public var errorDescription: String? {
        return "error.cant_create_eos".localized
    }
}

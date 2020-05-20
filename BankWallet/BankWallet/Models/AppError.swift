import Foundation

enum AppError: Error {
    case noConnection
    case incubedNotReachable
    case eos(reason: EosError)
    case binance(reason: BinanceError)
    case wordsValidation(reason: WordsValidationError)
    case unknownError

    enum WordsValidationError: Error {
        case emptyWords
        case invalidConfirmation
        case invalidWords
    }

    enum EosError: Error {
        case selfTransfer
        case accountNotExist
        case insufficientRam
        case invalidPrivateKey
    }

    enum BinanceError: Error {
        case memoRequired
        case onlyDigitsAllowed
    }
}


extension AppError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .noConnection: return "alert.no_internet".localized
        case .incubedNotReachable: return "error.incubed_not_reachable".localized
        case .eos(let reason):
            switch reason {
            case .selfTransfer: return "error.send_eos.self_transfer".localized
            case .accountNotExist: return "error.send_eos.account_not_exist".localized
            case .insufficientRam: return "error.send_eos.insufficient_ram".localized
            case .invalidPrivateKey: return "error.invalid_eos_key".localized
            }
        case .binance(let reason):
            switch reason {
            case .memoRequired: return "error.send_binance.memo_required".localized
            case .onlyDigitsAllowed: return "error.send_binance.only_digits_allowed".localized
            }
        case .wordsValidation(let reason):
            switch reason {
            case .emptyWords: return "words_validator.empty_words".localized
            case .invalidConfirmation: return "words_validator.invalid_confirmation".localized
            case .invalidWords: return "restore.validation_failed".localized

            }
        case .unknownError: return "Unknown Error"
        }

    }

}

import Foundation

enum AppError: Error {
    case noConnection
    case incubedNotReachable
    case eos(reason: EosError)
    case binance(reason: BinanceError)
    case zcash(reason: ZcashError)
    case wordsChecksum
    case addressInvalid
    case notSupportedByHodler
    case unknownError

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

    enum ZcashError: Error {
        case sendToSelf
        case transparentAddress
    }
}


extension AppError: LocalizedError {

    var errorDescription: String? {
        switch self {
        case .noConnection: return "alert.no_internet".localized
        case .incubedNotReachable: return "error.incubed_not_reachable".localized
        case .eos(let reason):
            switch reason {
            case .selfTransfer: return "error.send.self_transfer".localized
            case .accountNotExist: return "error.send_eos.account_not_exist".localized
            case .insufficientRam: return "error.send_eos.insufficient_ram".localized
            case .invalidPrivateKey: return "error.invalid_eos_key".localized
            }
        case .binance(let reason):
            switch reason {
            case .memoRequired: return "error.send_binance.memo_required".localized
            case .onlyDigitsAllowed: return "error.send_binance.only_digits_allowed".localized
            }
        case .zcash(let reason):
            switch reason {
            case .sendToSelf: return "error.send.self_transfer".localized
            case .transparentAddress: return "error.send_z_cash.transparent_address".localized
            }
        case .wordsChecksum:
            return "restore.checksum_error".localized
        case .addressInvalid: return "send.error.invalid_address".localized
        case .notSupportedByHodler: return "send.hodler_error.unsupported_address".localized
        case .unknownError: return "Unknown Error"
        }

    }

}

import EthereumKit
import FeeRateKit
import EosKit

// use convertedError to convert user relevant errors from kits to show them localized in UI
// localize converted error via LocalizedErrors
// other errors prevented either in the Kit logic or via business logic of the app but need to be shown in debug routine

protocol ConvertibleError: Error {
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

extension Error {

    var localizedDescription: String {
        if let localizedError = self as? LocalizedError, let errorDescription = localizedError.errorDescription {
            return errorDescription
        } else {
            return "\("alert.unknown_error".localized) \(String(reflecting: self))"
        }
    }

}

// converted errors

extension EthereumKit.NetworkError: ConvertibleError {

    var convertedError: Error {
        switch self {
        case .noConnection: return ConnectionError.noConnection
        default: return self
        }
    }

}

extension FeeRateKit.NetworkError {

    var convertedError: Error {
        switch self {
        case .noConnection: return ConnectionError.noConnection
        default: return self
        }
    }

}

extension NetworkManager.NetworkError {

    var convertedError: Error {
        switch self {
        case .noConnection: return ConnectionError.noConnection
        default: return self
        }
    }

}

extension BackendError {

    var convertedError: Error {
        switch self {
        case .selfTransfer: return EosBackendError.selfTransfer
        case .accountNotExist: return EosBackendError.accountNotExist
        case .insufficientRam: return EosBackendError.insufficientRam
        case .unknown(let message): return EosBackendError.unknown(message: message)
        default: return self
        }
    }

}

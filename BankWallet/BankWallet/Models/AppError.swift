import EthereumKit
import HsToolKit

enum AppError: Error {
    case noConnection
    case unhandled(error: Error)
    case unknownError

    init(error: Error) {
        self = .unhandled(error: error)

        if case NetworkManager.RequestError.noResponse = error {
            self = .noConnection
        }

        if case Kit.SyncError.noNetworkConnection = error {
            self = .noConnection
        }
    }

}


extension AppError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .noConnection: return "alert.no_internet".localized
        case .unhandled(let error): return "Unhandled Error: \(error)"
        case .unknownError: return "Unknown Error"
        }
    }

}

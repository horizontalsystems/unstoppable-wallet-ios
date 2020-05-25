import Foundation

enum ConnectionError: LocalizedError {
    case noConnection

    public var errorDescription: String? {
        switch self {
        case .noConnection: return "alert.no_internet".localized
        }
    }

}

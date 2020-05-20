import Foundation

enum SendTransactionError: Error {
    case noFee
}

extension SendTransactionError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .noFee: return "alert.no_fee".localized
        }
    }

}

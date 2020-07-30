import Foundation

enum SendTransactionError: Error {
    case noFee
    case wrongAmount
}

extension SendTransactionError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .wrongAmount: return "alert.wrong_amount".localized
        case .noFee: return "alert.no_fee".localized
        }
    }

}

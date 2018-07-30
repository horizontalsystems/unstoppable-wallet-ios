import Foundation

class TransactionValidator {
    enum ValidationError: Error {
        case doesNotBelongToCurrentWallet
    }

    static let shared = TransactionValidator()

    func validate(message: TransactionMessage) throws {

    }
}

import Foundation

enum AddressService {
    enum AddressError: Error {
        case invalidAddress(blockchainName: String?)
    }
}

extension AddressService.AddressError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case let .invalidAddress(blockchainName):
            return ["send.error.invalid".localized, blockchainName, "send.error.address".localized]
                .compactMap { $0 }
                .joined(separator: " ")
        }
    }
}

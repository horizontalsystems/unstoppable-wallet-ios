import Foundation
import MarketKit

enum EvmSyncSourceUrlValidator {
    enum ValidationError: Error, Equatable {
        case invalid
    }

    static func validSchemes(blockchainType: BlockchainType) -> [String] {
        blockchainType == .tron ? ["http", "https"] : ["https", "wss"]
    }

    static func validate(urlString: String, blockchainType: BlockchainType) throws -> URL {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let url = URL(string: trimmed), let scheme = url.scheme, url.host != nil else {
            throw ValidationError.invalid
        }

        guard validSchemes(blockchainType: blockchainType).contains(scheme) else {
            throw ValidationError.invalid
        }

        return url
    }
}

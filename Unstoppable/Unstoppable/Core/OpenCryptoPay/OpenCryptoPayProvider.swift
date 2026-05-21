import Foundation
import HsToolKit

class OpenCryptoPayProvider {
    private let networkManager: NetworkManager
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601Flexible
        return decoder
    }()

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchPaymentDetails(url: URL) async throws -> Models.PaymentDetails {
        try await networkManager.fetch(url: url, decoder: decoder)
    }

    func fetchTransactionDetails(callback: URL, quoteId: String, method: String, asset: String) async throws -> Models.TransactionDetails {
        let parameters: [String: Any] = [
            "quote": quoteId,
            "method": method,
            "asset": asset,
        ]
        return try await networkManager.fetch(url: callback, parameters: parameters, decoder: decoder)
    }

    func submitProof(callback: URL, quote: String, method: String, proof: OpenCryptoPayProof) async throws {
        let txUrl = try Self.submissionUrl(from: callback)

        var parameters: [String: Any] = ["quote": quote, "method": method]
        switch proof {
        case let .hex(hex): parameters["hex"] = hex
        case let .tx(hash): parameters["tx"] = hash
        }

        // 2xx — payment confirmed. Body is irrelevant.
        let _: EmptySubmissionResponse = try await networkManager.fetch(url: txUrl, parameters: parameters)
    }

    // Swap first `/cb/` segment for `/tx/`, keep everything else.
    static func submissionUrl(from callback: URL) throws -> URL {
        guard var urlComponents = URLComponents(url: callback, resolvingAgainstBaseURL: false) else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }
        guard let cbRange = urlComponents.path.range(of: "/cb/") else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }
        urlComponents.path = urlComponents.path.replacingCharacters(in: cbRange, with: "/tx/")

        guard let url = urlComponents.url else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }

        return url
    }
}

private struct EmptySubmissionResponse: Decodable {
    init(from _: Decoder) {}
}

extension OpenCryptoPayProvider {
    enum Models {
        struct PaymentDetails: Decodable {
            let id: String
            let callback: URL
            let recipient: Recipient
            let quote: Quote
            let transferAmounts: [TransferAmount]
        }

        struct Recipient: Decodable {
            let name: String
            let mail: String?
            let website: String?
        }

        struct Quote: Decodable {
            let id: String
            let expiration: Date
        }

        struct TransferAmount: Decodable {
            let method: String
            let available: Bool
            let assets: [Asset]
        }

        struct Asset: Decodable {
            let asset: String
            let amount: Decimal

            private enum CodingKeys: String, CodingKey { case asset, amount }

            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                asset = try c.decode(String.self, forKey: .asset)
                // OCP spec returns amount as a quoted string ("0.00001069"); JSONDecoder won't coerce it to Decimal.
                let raw = try c.decode(String.self, forKey: .amount)
                guard let decimal = Decimal(string: raw, locale: Locale(identifier: "en_US_POSIX")) else {
                    throw DecodingError.dataCorruptedError(forKey: .amount, in: c,
                                                           debugDescription: "Invalid decimal: \(raw)")
                }
                amount = decimal
            }
        }

        struct TransactionDetails: Decodable {
            let expiryDate: Date
            let blockchain: String
            let uri: String
        }
    }
}

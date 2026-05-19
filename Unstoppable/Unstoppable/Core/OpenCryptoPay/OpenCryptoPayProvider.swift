import Foundation
import HsToolKit

class OpenCryptoPayProvider {
    private let networkManager: NetworkManager
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        // Server returns ISO-8601 with milliseconds ("2025-07-16T01:20:06.476Z").
        // .iso8601 rejects fractional seconds, so accept both shapes.
        let withMs = ISO8601DateFormatter()
        withMs.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { dec in
            let s = try dec.singleValueContainer().decode(String.self)
            if let d = withMs.date(from: s) { return d }
            if let d = plain.date(from: s) { return d }
            throw try DecodingError.dataCorruptedError(in: dec.singleValueContainer(),
                                                       debugDescription: "Invalid ISO-8601 date: \(s)")
        }
        return decoder
    }()

    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func fetchPaymentDetails(url: URL) async throws -> Models.PaymentDetails {
        try await networkManager.fetch(url: url, decoder: decoder)
    }

    func fetchTransactionDetails(callback: URL, quoteId: String, method: String, asset: String) async throws -> Models.TransactionDetails {
        guard var components = URLComponents(url: callback, resolvingAgainstBaseURL: false) else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }
        var items = components.queryItems ?? []
        items.append(contentsOf: [
            URLQueryItem(name: "quote", value: quoteId),
            URLQueryItem(name: "method", value: method),
            URLQueryItem(name: "asset", value: asset),
        ])
        components.queryItems = items
        guard let url = components.url else {
            throw OpenCryptoPayManager.Error.malformedTxUri
        }
        return try await networkManager.fetch(url: url, decoder: decoder)
    }
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

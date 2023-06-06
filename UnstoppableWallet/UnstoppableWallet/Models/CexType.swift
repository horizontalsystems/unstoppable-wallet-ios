enum CexType {
    private static let separator = "@"
    private static let binanceId = "binance"
    private static let coinzixId = "coinzix"

    case binance(apiKey: String, secret: String)
    case coinzix(authToken: String, secret: String)

    var uniqueId: String {
        switch self {
        case .binance(let apiKey, let secret): return [Self.binanceId, apiKey, secret].joined(separator: Self.separator)
        case .coinzix(let authToken, let secret): return [Self.coinzixId, authToken, secret].joined(separator: Self.separator)
        }
    }

    var title: String {
        switch self {
        case .binance: return "Binance"
        case .coinzix: return "Coinzix"
        }
    }

    static func decode(uniqueId: String) -> CexType? {
        let parts = uniqueId.components(separatedBy: Self.separator)

        guard let firstPart = parts.first else {
            return nil
        }

        switch firstPart {
        case binanceId:
            guard parts.count == 3 else {
                return nil
            }

            return .binance(apiKey: parts[1], secret: parts[2])
        case coinzixId:
            guard parts.count == 3 else {
                return nil
            }

            return .coinzix(authToken: parts[1], secret: parts[2])
        default:
            return nil
        }
    }

}

extension CexType: Hashable {

    public static func ==(lhs: CexType, rhs: CexType) -> Bool {
        switch (lhs, rhs) {
        case (let .binance(lhsApiKey, lhsSecret), let .binance(rhsApiKey, rhsSecret)):
            return lhsApiKey == rhsApiKey && lhsSecret == rhsSecret
        case (let .coinzix(lhsAuthToken, lhsSecret), let .coinzix(rhsAuthToken, rhsSecret)):
            return lhsAuthToken == rhsAuthToken && lhsSecret == rhsSecret
        default:
            return false
        }
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case .binance(let apiKey, let secret):
            hasher.combine("binance")
            hasher.combine(apiKey)
            hasher.combine(secret)
        case .coinzix(let authToken, let secret):
            hasher.combine("coinzix")
            hasher.combine(authToken)
            hasher.combine(secret)
        }
    }

}

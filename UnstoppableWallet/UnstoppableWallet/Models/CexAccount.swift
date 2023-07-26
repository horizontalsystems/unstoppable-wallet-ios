import UIKit

protocol ICexAssetProvider {
    func assets() async throws -> [CexAssetResponse]
}

protocol ICexDepositProvider {
    func deposit(id: String, network: String?) async throws -> (String, String?)
}

protocol ICexWithdrawHandler {
    func withdraw(id: String, network: String?, address: String, amount: Decimal, feeFromAmount: Bool?) async throws -> Any
    func handle(result: Any, viewController: UIViewController)
}

enum CexAccount {
    private static let separator = "@"

    case binance(apiKey: String, secret: String)
    case coinzix(authToken: String, secret: String)

    var cex: Cex {
        switch self {
        case .binance: return .binance
        case .coinzix: return .coinzix
        }
    }

    var uniqueId: String {
        switch self {
        case .binance(let apiKey, let secret): return [Cex.binance.rawValue, apiKey, secret].joined(separator: Self.separator)
        case .coinzix(let authToken, let secret): return [Cex.coinzix.rawValue, authToken, secret].joined(separator: Self.separator)
        }
    }

    static func decode(uniqueId: String) -> CexAccount? {
        let parts = uniqueId.components(separatedBy: Self.separator)

        guard let firstPart = parts.first else {
            return nil
        }

        switch firstPart {
        case Cex.binance.rawValue:
            guard parts.count == 3 else {
                return nil
            }

            return .binance(apiKey: parts[1], secret: parts[2])
        case Cex.coinzix.rawValue:
            guard parts.count == 3 else {
                return nil
            }

            return .coinzix(authToken: parts[1], secret: parts[2])
        default:
            return nil
        }
    }

}

extension CexAccount {

    var assetProvider: ICexAssetProvider {
        switch self {
        case .binance(let apiKey, let secret): return BinanceCexProvider(networkManager: App.shared.networkManager, apiKey: apiKey, secret: secret)
        case .coinzix(let authToken, let secret): return CoinzixCexProvider(networkManager: App.shared.networkManager, authToken: authToken, secret: secret)
        }
    }

    var depositProvider: ICexDepositProvider {
        switch self {
        case .binance(let apiKey, let secret): return BinanceCexProvider(networkManager: App.shared.networkManager, apiKey: apiKey, secret: secret)
        case .coinzix(let authToken, let secret): return CoinzixCexProvider(networkManager: App.shared.networkManager, authToken: authToken, secret: secret)
        }
    }

    var withdrawHandler: ICexWithdrawHandler {
        switch self {
        case .binance(let apiKey, let secret):
            let provider = BinanceCexProvider(networkManager: App.shared.networkManager, apiKey: apiKey, secret: secret)
            return BinanceWithdrawHandler(provider: provider)
        case .coinzix(let authToken, let secret):
            let provider = CoinzixCexProvider(networkManager: App.shared.networkManager, authToken: authToken, secret: secret)
            return CoinzixWithdrawHandler(provider: provider)
        }
    }

}

extension CexAccount: Hashable {

    public static func ==(lhs: CexAccount, rhs: CexAccount) -> Bool {
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
            hasher.combine(Cex.binance.rawValue)
            hasher.combine(apiKey)
            hasher.combine(secret)
        case .coinzix(let authToken, let secret):
            hasher.combine(Cex.coinzix.rawValue)
            hasher.combine(authToken)
            hasher.combine(secret)
        }
    }

}

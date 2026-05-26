import Foundation
import MarketKit

public struct TokenAppValue: IAppValue {
    public let token: Token?

    // Inlined copy of StellarAdapter.maxValue (Unstoppable target). When StellarAdapter
    // moves to WalletCore, replace this constant with `StellarAdapter.maxValue` and delete this line.
    private static let stellarMaxValue: Decimal = Decimal(Int64.max) / 10_000_000

    public init(token: Token) {
        self.token = token
    }

    public var coin: Coin? { token?.coin }
    public var name: String { token?.coin.name ?? "" }
    public var code: String { token?.coin.code ?? "" }
    public var decimals: Int? { token?.decimals }
    public var tokenProtocol: TokenProtocol? { token?.type.tokenProtocol }

    public func isSameKind(as other: any IAppValue) -> Bool {
        (other as? TokenAppValue).map { $0.token == token } ?? false
    }

    public func isMaxValue(value: Decimal) -> Bool {
        guard let token else { return false }
        if token.blockchain.type == .stellar {
            return value == Self.stellarMaxValue
        }
        return value.isMaxValue(decimals: token.decimals)
    }
}

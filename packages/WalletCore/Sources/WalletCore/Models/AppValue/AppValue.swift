import Foundation
import MarketKit

public struct AppValue {
    public let kind: any IAppValue
    public let value: Decimal

    public init(kind: any IAppValue, value: Decimal) {
        self.kind = kind
        self.value = value
    }

    public init(token: Token, value: Decimal) {
        self.init(kind: TokenAppValue(token: token), value: value)
    }

    public init(coin: Coin, decimals: Int, value: Decimal) {
        self.init(kind: CoinAppValue(coin: coin, decimals: decimals), value: value)
    }

    public init(tokenName: String, tokenCode: String, tokenDecimals: Int, value: Decimal) {
        self.init(kind: Eip20TokenAppValue(tokenName: tokenName, tokenCode: tokenCode, tokenDecimals: tokenDecimals), value: value)
    }

    public init(value: Decimal) {
        self.init(kind: RawAppValue(), value: value)
    }

    public var token: Token? { kind.token }
    public var coin: Coin? { kind.coin }
    public var name: String { kind.name }
    public var code: String { kind.code }
    public var decimals: Int? { kind.decimals }
    public var tokenProtocol: TokenProtocol? { kind.tokenProtocol }
    public var zeroValue: Bool { value == 0 }
    public var isMaxValue: Bool { kind.isMaxValue(value: value) }

    public var abs: AppValue {
        AppValue(kind: kind, value: value.magnitude)
    }

    public var negative: AppValue {
        AppValue(kind: kind, value: Decimal(sign: .minus, exponent: value.exponent, significand: value.significand))
    }

    public var infinity: String {
        "∞ \(code)"
    }

    public func formattedWith(rounding: Bool, signType: ValueFormatter.SignType = .never) -> String? {
        if rounding {
            return formattedShort(signType: signType)
        }
        return formattedFull(signType: signType)
    }

    public func formattedFull(signType: ValueFormatter.SignType = .never, showCode: Bool = true) -> String? {
        kind.formattedFull(value: value, signType: signType, showCode: showCode)
    }

    public func formattedShort(signType: ValueFormatter.SignType = .never) -> String? {
        kind.formattedShort(value: value, signType: signType)
    }
}

extension AppValue: Equatable {
    public static func == (lhs: AppValue, rhs: AppValue) -> Bool {
        lhs.kind.isSameKind(as: rhs.kind) && lhs.value == rhs.value
    }
}

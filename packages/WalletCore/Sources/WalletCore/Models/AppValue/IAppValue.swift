import Foundation
import MarketKit

public protocol IAppValue {
    var token: Token? { get }
    var coin: Coin? { get }
    var name: String { get }
    var code: String { get }
    var decimals: Int? { get }
    var tokenProtocol: TokenProtocol? { get }

    func isSameKind(as other: any IAppValue) -> Bool
    func formattedFull(value: Decimal, signType: ValueFormatter.SignType, showCode: Bool) -> String?
    func formattedShort(value: Decimal, signType: ValueFormatter.SignType) -> String?
    func isMaxValue(value: Decimal) -> Bool
}

public extension IAppValue {
    var token: Token? { nil }
    var coin: Coin? { nil }
    var decimals: Int? { nil }
    var tokenProtocol: TokenProtocol? { nil }

    func formattedFull(value: Decimal, signType: ValueFormatter.SignType, showCode: Bool) -> String? {
        guard let decimals else { return nil }
        return ValueFormatter.instance.formatFull(value: value, decimalCount: decimals, symbol: showCode ? code : nil, signType: signType)
    }

    func formattedShort(value: Decimal, signType: ValueFormatter.SignType) -> String? {
        guard let decimals else { return nil }
        return ValueFormatter.instance.formatShort(value: value, decimalCount: decimals, symbol: code, signType: signType)
    }

    func isMaxValue(value: Decimal) -> Bool {
        decimals.map { value.isMaxValue(decimals: $0) } ?? false
    }
}

import Foundation
import MarketKit

public struct Eip20TokenAppValue: IAppValue {
    public let tokenName: String
    public let tokenCode: String
    public let tokenDecimals: Int

    public init(tokenName: String, tokenCode: String, tokenDecimals: Int) {
        self.tokenName = tokenName
        self.tokenCode = tokenCode
        self.tokenDecimals = tokenDecimals
    }

    public var name: String { tokenName }
    public var code: String { tokenCode }
    public var decimals: Int? { tokenDecimals }
    public var tokenProtocol: TokenProtocol? { .eip20 }

    public func isSameKind(as other: any IAppValue) -> Bool {
        guard let other = other as? Eip20TokenAppValue else { return false }
        return other.tokenName == tokenName && other.tokenCode == tokenCode && other.tokenDecimals == tokenDecimals
    }
}

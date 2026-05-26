import Foundation

public struct RawAppValue: IAppValue {
    public init() {}

    public var name: String { "" }
    public var code: String { "" }

    public func isSameKind(as other: any IAppValue) -> Bool { other is RawAppValue }

    public func formattedFull(value _: Decimal, signType _: ValueFormatter.SignType, showCode _: Bool) -> String? { nil }
    public func formattedShort(value _: Decimal, signType _: ValueFormatter.SignType) -> String? { nil }
    public func isMaxValue(value _: Decimal) -> Bool { false }
}

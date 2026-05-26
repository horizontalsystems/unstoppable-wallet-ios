import Foundation

public enum FeePriceScale {
    case satoshi
    case gwei
    case nAvax

    public var scaleValue: Int {
        switch self {
        case .satoshi: return 1
        case .gwei, .nAvax: return 1_000_000_000
        }
    }

    public var scaleDecimals: Int {
        switch self {
        case .satoshi: return 0
        case .gwei, .nAvax: return 9
        }
    }

    public var unit: String {
        switch self {
        case .satoshi: return "sat/byte"
        case .gwei: return "Gwei"
        case .nAvax: return "nAVAX"
        }
    }

    public func description(value: Float, showSymbol: Bool = true) -> String {
        ValueFormatter.instance.formatFull(value: Decimal(Double(value)), decimalCount: 9, symbol: showSymbol ? unit : nil, signType: .never) ?? value.description
    }

    public func wrap(value: Int, step: Int) -> Float {
        Float(value / step * step) / Float(scaleValue)
    }

    public func wrap(value: Float, step: Int) -> Float {
        let intValue = Int(value * Float(scaleValue))
        return wrap(value: intValue, step: step)
    }
}

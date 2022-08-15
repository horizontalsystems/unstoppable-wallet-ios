import Foundation

enum FeePriceScale {
    case satoshi
    case gwei
    case nAvax

    var scaleValue: Int {
        switch self {
        case .satoshi: return 1
        case .gwei, .nAvax: return 1_000_000_000
        }
    }

    var unit: String {
        switch self {
        case .satoshi: return "sat/byte"
        case .gwei: return "Gwei"
        case .nAvax: return "nAVAX"
        }
    }

    func description(value: Float, showSymbol: Bool = true) -> String {
        ValueFormatter.instance.formatFull(value: Decimal(Double(value)), decimalCount: 9, symbol: showSymbol ? unit : nil, showSign: false) ?? value.description
    }

    func wrap(value: Int, step: Int) -> Float {
        Float(value / step * step) / Float(scaleValue)
    }

    func wrap(value: Float, step: Int) -> Float {
        let intValue = Int(value * Float(scaleValue))
        return wrap(value: intValue, step: step)
    }
}

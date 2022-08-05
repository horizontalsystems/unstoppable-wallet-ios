import Foundation

enum FeePriceScale: Int {
    case satoshi = 1
    case gwei = 1_000_000_000

    var value: Int {
        rawValue
    }

    var unit: String {
        switch self {
        case .satoshi: return "sat/byte"
        case .gwei: return "gwei"
        }
    }

    func description(value: Float, showSymbol: Bool = true) -> String {
        ValueFormatter.instance.formatFull(value: Decimal(Double(value)), decimalCount: 8, symbol: showSymbol ? unit : nil, showSign: false) ?? value.description
    }

    func wrap(value: Int, step: Int) -> Float {
        Float(value / step * step) / Float(self.value)
    }

    func wrap(value: Float, step: Int) -> Float {
        let intValue = Int(value * Float(rawValue))
        return wrap(value: intValue, step: step)
    }
}

import Foundation
import SwiftUI

enum Diff {
    case percent(value: Decimal)
    case change(value: Decimal, currency: Currency)

    static func text(diff: Decimal?, expired: Bool) -> CustomStringConvertible {
        text(diff: diff.map { .percent(value: $0) }, expired: expired)
    }

    static func text(diff: Diff?, expired: Bool) -> CustomStringConvertible {
        if let (text, value) = resolved(diff: diff) {
            return ComponentText(text: text, colorStyle: value == 0 ? .secondary : (value.isSignMinus ? .red : .green), dimmed: expired)
        } else {
            return "----"
        }
    }

    private static func resolved(diff: Diff?) -> (String, Decimal)? {
        guard let diff else {
            return nil
        }

        switch diff {
        case let .percent(value): return ValueFormatter.instance.format(percentValue: value).map { ($0, value) }
        case let .change(value, currency): return ValueFormatter.instance.formatShort(currency: currency, value: value, signType: .always).map { ($0, value) }
        }
    }
}

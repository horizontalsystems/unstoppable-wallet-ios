import SnapKit
import UIKit

class DiffLabel: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)

        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(value: Decimal?, highlightText: Bool = true) {
        text = Self.formatted(value: value)
        textColor = Self.color(value: value, highlight: highlightText)
    }

    func set(text: String?, color: UIColor) {
        self.text = text
        textColor = color
    }

    func clear() {
        text = nil
    }
}

extension DiffLabel {
    static func formatted(value: Decimal?) -> String? {
        guard let value else {
            return "----"
        }

        return ValueFormatter.instance.format(percentValue: value)
    }

    static func color(value: Decimal?, highlight: Bool = true) -> UIColor {
        guard let value else {
            return .themeGray50
        }

        guard highlight else {
            return .themeGray
        }

        return value.isSignMinus ? .themeLucian : .themeRemus
    }
}

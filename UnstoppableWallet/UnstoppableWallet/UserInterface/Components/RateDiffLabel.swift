import UIKit
import SnapKit

class RateDiffLabel: UILabel {

    override init(frame: CGRect) {
        super.init(frame: frame)

        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(value: Decimal?, highlightText: Bool = true) {
        guard let value = value else {
            text = "----"
            textColor = .themeGray50
            return
        }

        let color: UIColor = value.isSignMinus ? .themeLucian : .themeRemus
        textColor = highlightText ? color : .themeGray

        text = ValueFormatter.instance.format(percentValue: value)
    }

    func clear() {
        text = nil
    }

}

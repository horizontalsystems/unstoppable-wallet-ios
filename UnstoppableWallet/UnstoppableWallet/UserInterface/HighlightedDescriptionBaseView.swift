import UIKit

class HighlightedDescriptionBaseView: UIView {
    internal static let font: UIFont = .subhead2
    internal static let sidePadding: CGFloat = .margin16
    internal static let verticalPadding: CGFloat = .margin12

    internal let label = UILabel()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .themeYellow20
        borderColor = .themeYellowD
        borderWidth = 1
        cornerRadius = .cornerRadius12
        layer.cornerCurve = .continuous

        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(style: Style) {
        switch style {
        case .yellow:
            backgroundColor = .themeYellow20
            borderColor = .themeYellowD
        case .red:
            backgroundColor = UIColor(hex: 0xff4820, alpha: 0.2)
            borderColor = .themeLucian
        }
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

extension HighlightedDescriptionBaseView {

    enum Style {
        case yellow
        case red
    }

}

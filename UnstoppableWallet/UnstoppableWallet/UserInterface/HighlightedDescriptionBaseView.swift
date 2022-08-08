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
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

import UIKit

class HighlightedDescriptionBaseView: UIView {
    internal static let font: UIFont = .subhead2
    internal static let sidePadding: CGFloat = .margin12
    internal static let verticalPadding: CGFloat = .margin12

    internal let label = UILabel()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .themeYellow20
        borderColor = .themeJacob
        borderWidth = 1
        cornerRadius = .cornerRadius2x
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var text: String? {
        get { label.text }
        set { label.text = newValue }
    }

}

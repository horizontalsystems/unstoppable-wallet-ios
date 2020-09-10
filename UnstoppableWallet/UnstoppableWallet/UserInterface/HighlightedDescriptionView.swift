import UIKit
import SnapKit

open class HighlightedDescriptionView: UIView {
    private static let font: UIFont = .subhead2
    private static let sidePadding: CGFloat = .margin3x
    private static let verticalPadding: CGFloat = .margin3x

    private let label = UILabel()

    public init() {
        super.init(frame: .zero)

        backgroundColor = .themeLawrence
        borderColor = .themeJacob
        borderWidth = 1
        cornerRadius = .cornerRadius2x

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(HighlightedDescriptionView.sidePadding)
            maker.top.bottom.equalToSuperview().inset(HighlightedDescriptionView.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = HighlightedDescriptionView.font
        label.textColor = .themeOz
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(text: String?) {
        label.text = text
    }

}

extension HighlightedDescriptionView {

    public static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return textHeight + 2 * verticalPadding
    }

}

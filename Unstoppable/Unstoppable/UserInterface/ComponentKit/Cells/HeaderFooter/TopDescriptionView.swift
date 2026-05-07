import SnapKit
import UIKit

open class TopDescriptionView: UIView {
    private static let sideMargin: CGFloat = .margin6x
    private static let topMargin: CGFloat = .margin3x
    private static let bottomMargin: CGFloat = .margin6x
    private static let font: UIFont = .subhead2

    private let label = UILabel()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        label.numberOfLines = 0
        label.font = TopDescriptionView.font
        label.textColor = .themeGray

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(TopDescriptionView.sideMargin)
            maker.top.equalToSuperview().offset(TopDescriptionView.topMargin)
            maker.bottom.equalToSuperview().inset(TopDescriptionView.bottomMargin)
        }
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(text: String?) {
        label.text = text
    }
}

public extension TopDescriptionView {
    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * TopDescriptionView.sideMargin, font: TopDescriptionView.font)
        return textHeight + TopDescriptionView.topMargin + TopDescriptionView.bottomMargin
    }
}

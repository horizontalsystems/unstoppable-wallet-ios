import UIKit

class PrivacyInfoHeaderView: UITableViewHeaderFooterView {
    private static let topPadding = CGFloat.margin6x
    private static let sidePadding = CGFloat.margin6x
    private static let font: UIFont = .headline2

    private let separator = UIView()
    private let label = UILabel()

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        separator.backgroundColor = .themeSteel20
        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PrivacyInfoHeaderView.sidePadding)
            maker.top.equalToSuperview().inset(PrivacyInfoHeaderView.topPadding)
        }

        label.numberOfLines = 0
        label.font = PrivacyInfoHeaderView.font
        label.textColor = .themeJacob
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func bind(text: String?, first: Bool) {
        separator.isHidden = !first
        label.text = text
    }

}

extension PrivacyInfoHeaderView {

    public static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * sidePadding, font: font)
        return textHeight + topPadding
    }

}

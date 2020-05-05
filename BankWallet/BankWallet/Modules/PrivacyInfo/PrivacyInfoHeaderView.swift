import UIKit

class PrivacyInfoHeaderView: UITableViewHeaderFooterView {
    private static let topPadding = CGFloat.margin6x
    private static let horizontalPadding = CGFloat.margin6x
    private static let font: UIFont = .headline2

    private let separator = UIView()
    private let label = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separator.backgroundColor = .themeSteel20

        addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PrivacyInfoHeaderView.horizontalPadding)
            maker.top.equalToSuperview().inset(PrivacyInfoHeaderView.topPadding)
        }

        label.numberOfLines = 0
        label.font = PrivacyInfoHeaderView.font
        label.textColor = .themeJacob
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?, showSeparator: Bool) {
        separator.isHidden = !showSeparator
        label.text = text
    }

}

extension PrivacyInfoHeaderView {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font)
        return textHeight + topPadding
    }

}
